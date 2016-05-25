namespace :migrations do

  desc "waive coverage for employee"
  task :waive_coverage_for_employee, [:first_name, :last_name, :dob] => :environment do |task, args|

    person = Person.where(:first_name => /#{args[:first_name]}/i, :last_name => /#{args[:last_name]}/i, :dob => args[:dob]).first
    census_employees = CensusEmployee.where(:first_name => /#{args[:first_name]}/i, :last_name => /#{args[:last_name]}/i, :dob => args[:dob])

    if census_employees.size > 1
      raise "more than 1 census employee found"
    end

    family = person.primary_family

    enrollment = family.active_household.hbx_enrollments.new
    enrollment.coverage_kind = "health"
    enrollment.enrollment_kind = "open_enrollment"
    enrollment.kind = "employer_sponsored"

    benefit_group_assignment = census_employees.first.active_benefit_group_assignment

    enrollment.benefit_group_assignment_id = benefit_group_assignment.id
    enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id
    enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
    enrollment.waiver_reason = "I do not have other coverage"
    enrollment.save

    enrollment.waive_coverage!

    puts "Created waived enrollment for #{person.full_name}."
  end
end