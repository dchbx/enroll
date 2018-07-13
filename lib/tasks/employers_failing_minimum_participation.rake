require 'csv'
namespace :reports do
  namespace :shop do

    desc "Report of Initial/Renewal/Conversion ERs that Failed Minimum Participation or Non-Owner Rule"
    task :employers_failing_minimum_participation => :environment do
      include Config::AcaHelper

      window_date = Date.today
      valid_states = PlanYear::RENEWING_PUBLISHED_STATE + PlanYear::PUBLISHED
      employers = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {
        :open_enrollment_start_on => {"$lte" => window_date},
        :open_enrollment_end_on => {"$gte" => window_date},
        :aasm_state.in => valid_states}})

      file_name = fetch_file_format('employers_failing_minimum_participation', 'EMPLOYERSFAILINGMINIMUMPARTICIPATION')

      field_names  = [ "FEIN", "Legal Name", "DBA Name", "Plan Year Effective Date", "OE Close Date", "Type of Failure", "Type of Group", "Conversion ?" ]

      CSV.open(file_name, "w") do |csv|
        csv << field_names

        employers.each do |employer|
          employer_profile = employer.employer_profile
          plan_year = employer_profile.plan_years.detect do |py|
             (py.open_enrollment_start_on <= window_date) &&
               (py.open_enrollment_end_on >= window_date) &&
               valid_states.include?(py.aasm_state)
          end

          enrollment_errors = plan_year.enrollment_errors
          
          if enrollment_errors.any?
            csv << [
              employer.fein,
              employer.legal_name,
              employer.dba,
              plan_year.start_on,
              plan_year.open_enrollment_end_on,
              clean_JSON_dump(JSON.dump(enrollment_errors)),
              (PlanYear::RENEWING_PUBLISHED_STATE.include?(plan_year.aasm_state) ? "renewing" : "initial"),
              employer_profile.is_conversion?
            ]
          end

        end

      end

      pubber = Publishers::Legacy::EmployersFailingParticipationReportPublisher.new
      pubber.publish URI.join("file://", file_name)
    end

    def clean_JSON_dump(json_errors)
      errors = Array.new
      errors << "Mimimum Participation" if json_errors["enrollment_ratio"].present?
      errors << "Non-Owner" if json_errors["non_business_owner_enrollment_count"].present?
      errors << "At least one Employee" if json_errors["eligible_to_enroll_count"].present?
      return errors.join(" & ")
    end  

  end
end
