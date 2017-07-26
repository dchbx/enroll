require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateRenewalPlanYearAndEnrollment < MongoidMigrationTask

  def migrate
    organization = Organization.where(:'employer_profile'.exists=>true, fein: ENV['fein']).first
    action = ENV['action'].to_s

    if organization.present? && organization.employer_profile.active_plan_year.present?
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
      puts "No active plan year found" unless Rails.env.test? &&   organization.employer_profile.active_plan_year.blank?
    end
  end

  def create_renewal_plan_year(organization)
    renewal_factory = Factories::PlanYearRenewalFactory.new
    renewal_factory.employer_profile = organization.employer_profile
    renewal_factory.is_congress = false
    renewal_factory.renew
    puts "Renewal Plan year created" unless Rails.env.test?
  end

  def create_renewal_plan_year_passive_renewal(organization)
    create_renewal_plan_year(organization)
    renewing_plan_year = organization.employer_profile.plan_years.renewing.first
    if renewing_plan_year.present? && renewing_plan_year.may_force_publish?
      renewing_plan_year.force_publish!
      puts "passive renewal generated" unless Rails.env.test?
    end
  end

  def trigger_passive_renewals(organization)
    renewing_plan_year= organization.employer_profile.plan_years.renewing_published_state.first
    if renewing_plan_year.present?
      renewing_plan_year.trigger_passive_renewals
      puts "passive renewal generated" unless Rails.env.test?
    end
  end

end
