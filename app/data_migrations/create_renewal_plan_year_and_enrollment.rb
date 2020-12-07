# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateRenewalPlanYearAndEnrollment < MongoidMigrationTask

  def migrate
    if ENV['action'].to_s == "trigger_renewal_py_for_employers"
      trigger_renewal_py_for_employers
       return
    end

    if ENV['action'].to_s == "trigger_passive_renewals_for_employers"
      trigger_passive_renewals_by_effective_date
      return
    end

    organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(fein: ENV['fein']).first
    action = ENV['action'].to_s

    if organization.present? && organization.employer_profile.active_benefit_application.present?
      case action
      when "renewal_plan_year"
        create_renewal_plan_year(organization)
      when "renewal_plan_year_passive_renewal"
        create_renewal_plan_year_passive_renewal(organization)
      when "trigger_passive_renewal"
        trigger_passive_renewals(organization)
      else
        puts "Invalid action" unless Rails.env.test?
      end
    else
      puts "No Oganization found" unless Rails.env.test? && organization.blank?
      puts "No active plan year found" unless Rails.env.test? && organization.employer_profile.active_benefit_application.blank?
    end
  end

  def create_renewal_plan_year(organization)
    benefit_application = organization.employer_profile.active_benefit_application
    BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application).renew_application
    puts "triggered renewal plan year for #{organization.legal_name}" unless Rails.env.test?
  end

  def create_renewal_plan_year_passive_renewal(organization)
    create_renewal_plan_year(organization)
    renewing_plan_year = organization.employer_profile.renewing_benefit_application
    if renewing_plan_year.present? && renewing_plan_year.may_simulate_provisional_renewal?
      renewing_plan_year.simulate_provisional_renewal!
      puts "passive renewal generated" unless Rails.env.test?
    end
  end

  def trigger_passive_renewals(organization)
    renewing_plan_year = organization.employer_profile.renewing_benefit_application
    if renewing_plan_year.present?
      renewing_plan_year.renew_benefit_package_members
      puts "passive renewal generated for organization #{organization.fein}" unless Rails.env.test?
    end
  end

  def trigger_renewal_py_for_employers
    benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications.exists => true,
                                                                                          :benefit_applications =>
                                                                       { :$elemMatch =>
                                                                             {
                                                                               :'effective_period.min' => Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y"),
                                                                               :aasm_state.in => [:active]
                                                                             }})

    benefit_sponsorships.no_timeout.each do |benefit_sponsorship|
      benefit_application = benefit_sponsorship.benefit_applications.where(:'effective_period.min' => Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y"),:aasm_state => :active).first
      if benefit_application.present? && benefit_sponsorship.benefit_applications.detect(&:is_renewing?).blank?
        organization = benefit_application.sponsor_profile.organization
        create_renewal_plan_year(organization)
      end
    rescue StandardError => e
      puts "Unable to generate renewal PY for employer #{organization.fein} due to #{e}"
    end
  end

  def trigger_passive_renewals_by_effective_date
    benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications =>
                                                                                            { :$elemMatch =>
                                                                                                {
                                                                                                  :predecessor_id => { :$exists => true, :$ne => nil },
                                                                                                  :'effective_period.min' => Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y"),
                                                                                                  :aasm_state.in => [:enrollment_open]
                                                                                                }})

    benefit_sponsorships.no_timeout.each do |benefit_sponsorship|
      organization = benefit_sponsorship.organization

      next if organization.is_a_fehb_profile?

      renewing_plan_year = organization.employer_profile.benefit_applications.where(:predecessor_id => { :$exists => true, :$ne => nil }, :aasm_state.in => [:enrollment_open]).first

      next if renewing_plan_year.blank?

      renewing_plan_year.benefit_packages.each do |benefit_package|
        benefit_package.census_employees_assigned_on(benefit_package.effective_period.min).each do |census_employee|
          next if census_employee.renewal_benefit_group_assignment.blank?
          next if (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::WAIVED_STATUSES).include?(census_employee.renewal_benefit_group_assignment&.hbx_enrollment&.aasm_state)

          if Rails.env.test?
            benefit_package.renew_member_benefit(census_employee)
          else
            benefit_package.trigger_renew_employee_event(census_employee)
          end
        end
      end
      puts "passive renewal generated for organization #{organization.fein}" unless Rails.env.test?
    rescue StandardError => e
      puts "Unable to generate renewal PY for employer #{organization.fein} due to #{e}"
    end
  end
end