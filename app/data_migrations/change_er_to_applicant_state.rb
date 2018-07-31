require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeErToApplicantState < MongoidMigrationTask
  def migrate
    feins=ENV['feins'].split(' ').uniq
    feins.each do |fein|
      organizations = Organization.where(fein: fein)
      next puts "unable to find employer_profile with fein: #{fein}" if organizations.blank?

      if organizations.size > 1
        raise 'more than 1 employer found with given fein'
      end
      
      employer_profile = organizations.first.employer_profile
      plan_year = employer_profile.plan_years.where(aasm_state: ENV['plan_year_state'].to_s).first
      next puts "Present fein: #{fein} is found but it has different plan year assm state" if plan_year.nil?
      employer_profile.census_employees.each do |census_employee|
        assignments = census_employee.benefit_group_assignments.where(:benefit_group_id.in => plan_year.benefit_groups.map(&:id))
        assignments.each do |assignment|
          if assignment.may_delink_coverage?
            assignment.delink_coverage!
            assignment.update_attribute(:is_active, false)
          end
        end
      end
      employer_profile.revert_application! if employer_profile.may_revert_application?
    end
  end
end
