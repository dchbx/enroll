require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateRenewalPlanYearAndEnrollment < MongoidMigrationTask

  def migrate
     if ENV['action'].to_s == "trigger_renewal_py_for_employers"
       trigger_renewal_py_for_employers
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
      puts "No Oganization found" unless Rails.env.test? &&  organization.blank?
      puts "No active plan year found" unless Rails.env.test? &&   organization.employer_profile.active_benefit_application.blank?
    end
  end

  def create_renewal_plan_year(organization)
    benefit_application =  organization.employer_profile.active_benefit_application
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
      puts "passive renewal generated" unless Rails.env.test?
    end
  end

  def trigger_renewal_py_for_employers
    benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications'.exists => true,
                                                                   :'benefit_applications'=>
                                                                       { :$elemMatch =>
                                                                             {
                                                                                 :'effective_period.min' => Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y"),
                                                                                 :"aasm_state".in => [:active]
                                                                             }
                                                                       })

    benefit_sponsorships.each do |benefit_sponsorship|
      benefit_application = benefit_sponsorship.benefit_applications.where(:'effective_period.min' => Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y"),:"aasm_state" => :active).first
      if benefit_application.present? && benefit_sponsorship.benefit_applications.detect{|b| b.is_renewing?}.blank?
        organization = benefit_application.sponsor_profile.organization
        create_renewal_plan_year(organization)
      end
    end
  end
end
