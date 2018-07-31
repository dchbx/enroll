require 'csv'
namespace :reports do
  namespace :shop do

    desc "Report of Initial/Renewal/Conversion ERs that Failed Minimum Participation or Non-Owner Rule"
    task :employers_failing_minimum_participation => :environment do
      include Config::AcaHelper

      window_date = Date.today
      valid_states = (BenefitSponsors::BenefitApplications::BenefitApplication::APPROVED_STATES - [:enrollment_closed])
      benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"benefit_applications.aasm_state".in => valid_states)

      employer_profiles = benefit_sponsorships.flat_map(&:benefit_applications).inject([]) do |array, benefit_application|
        array << benefit_application if benefit_application.open_enrollment_period.include?(window_date)
        array.flatten
      end.map(&:sponsor_profile).uniq

      file_name = fetch_file_format('employers_failing_minimum_participation', 'EMPLOYERSFAILINGMINIMUMPARTICIPATION')

      field_names  = [ "FEIN", "Legal Name", "DBA Name", "Plan Year Effective Date", "OE Close Date", "Type of Failure", "Type of Group", "Conversion ?" ]

      CSV.open(file_name, "w") do |csv|
        csv << field_names

        employer_profiles.each do |employer_profile|
          benefit_application = employer_profile.benefit_applications.detect do |benefit_application|
            (benefit_application.open_enrollment_period.include?(window_date)) && (valid_states.include?(benefit_application.aasm_state))
          end

          if benefit_application.present?
            enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
            policy = enrollment_policy.business_policies_for(benefit_application, :passes_open_enrollment_period_policy)
            if policy.present?
              policy.is_satisfied?(benefit_application)
              enrollment_errors = policy.fail_results

              if enrollment_errors.any?
                csv << [
                  employer_profile.fein,
                  employer_profile.legal_name,
                  employer_profile.dba,
                  benefit_application.start_on.to_date.to_s,
                  benefit_application.open_enrollment_end_on.to_date.to_s,
                  clean_JSON_dump(JSON.dump(enrollment_errors)),
                  (benefit_application.is_renewing? ? "renewing" : "initial"),
                  employer_profile.is_conversion?
                ]
              end
            end
          end
        end
      end

      if Rails.env.production?
        pubber = Publishers::Legacy::EmployersFailingParticipationReportPublisher.new
        pubber.publish URI.join("file://", file_name)
      end
    end

    def clean_JSON_dump(json_errors)
      errors = Array.new
      errors << "Mimimum Participation" if json_errors["minimum_participation_rule"].present?
      errors << "Non-Owner" if json_errors["non_business_owner_enrollment_count"].present?
      errors << "At least one Employee" if json_errors["minimum_eligible_member_count"].present?
      return errors.join(" & ")
    end
  end
end