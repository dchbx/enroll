require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBenefitGroup < MongoidMigrationTask
  def migrate
    Organization.all.each do |organization|
    employer_profile = organization.employer_profile
      if employer_profile.present? && employer_profile.plan_years.present?
        active_plan_year = employer_profile.plan_years.where(aasm_state: "active").first
        if employer_profile.renewing_plan_year.present? && active_plan_year.present?
          employer_profile.census_employees.each do |census_employee|
            if census_employee.renewal_published_benefit_group.present? && census_employee.active_benefit_group.blank?
              if census_employee.benefit_group_assignments.present?
                benefit_group_assignment = census_employee.benefit_group_assignments.first
                benefit_group_assignment.is_active = true
                benefit_group_assignment.save!
              end
            end
          end
        end
      end
    end
  end
end
      