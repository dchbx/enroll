require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateDentalRelationshipBenefits< MongoidMigrationTask

  def migrate
    begin
      plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
      organization = Organization.where(:'employer_profile'.exists=>true, fein: ENV['fein']).first
      if organization.present?
        benefit_group = organization.employer_profile.plan_years.where(start_on: plan_year_start_on).first.benefit_groups.where(id:ENV['benefit_group_id']).first
        dental_relationship_benefit = benefit_group.dental_relationship_benefits.where(relationship: ENV['relationship']).first
        dental_relationship_benefit.update_attributes!(offered:'false')
        puts "relationship offering updated" unless Rails.env.test?
      else
        Puts "No Organization found" unless Rails.env.test?
      end
    rescue => e
      puts "#{e}" unless Rails.env.test?
    end
  end
end
