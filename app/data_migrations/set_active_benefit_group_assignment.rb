require File.join(Rails.root, "lib/mongoid_migration_task")

class SetActiveBenefitGroupAssignment < MongoidMigrationTask

  def find_employers
    Organization.where(:"employer_profile.plan_years" => {
      :$elemMatch => {:start_on.gte => Date.new(2016,6,1), :start_on.lte => Date.new(2016,8,1), :aasm_state => 'active'}
      })
  end

  def find_assignments_for_benefit_groups(census_employee, bg_ids)
    census_employee.benefit_group_assignments.select do |assignment|
      bg_ids.include?(assignment.benefit_group_id)
    end
  end

  def migrate
    find_employers.each do |org|
      employer = org.employer_profile
      active_plan_year = employer.active_plan_year
      next unless active_plan_year
      
      bg_ids = active_plan_year.benefit_groups.map(&:id)
      employer.census_employees.non_terminated.each do |census_employee|

        active_assignment = census_employee.active_benefit_group_assignment
        next if active_assignment && bg_ids.include?(active_assignment.benefit_group_id)

        if active_assignment
          active_assignment.update_attributes(:is_active => false)
        end

        assignments = find_assignments_for_benefit_groups(census_employee, bg_ids)
        if assignments.any?
          assignments.first.make_active
          puts "Updated #{org.legal_name} -- #{census_employee.full_name}"
        else
          benefit_group = active_plan_year.default_benefit_group || active_plan_year.benefit_groups.first
          census_employee.add_benefit_group_assignment(benefit_group, benefit_group.start_on)
          census_employee.save!
          puts "Created #{org.legal_name} -- #{census_employee.full_name}"
        end
      end
    end
  end
end
