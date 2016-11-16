namespace :update_enroll do
  desc "find EE with coverage_waived benefit group assignment and associated to an enrollment in the auto-renewal state"
  task :ee_with_waived_bga_and_autorenewal_enrollment => :environment do
    total_count = 0
    people=Person.all



    #1) Query All Families SHOP 12/1 ERs AUTO renewing enrollments

    families=Family.all.by_enrollment_renewing.by_enrollment_shop_market.size
    families.each do |family|

      family.active_household.hbx_enrollments.map{|a|[ a.kind,a.coverage_kind,a.aasm_state,a.terminated_on]}
      family.active_household.hbx_enrollments.where(aasm_state:"auto_renewing").map{|a|[a.kind,a.coverage_kind]}

    end
    #2) Check if the family have current active coverage for same market kind, coverage kind. (edited)
    #3) If Step 2 returns false…then Auto renewal should be canceled
    #4) Lets export all the enrollments which fails step 2 into CSV file for business to reveiw

    people.each do |person|
      #first check has ee role has benefit_group_assignment
      if person.employee_roles.exists?
        employee_roles=person.employee_roles
        employee_roles.each do |employee_role|
            unless employee_role.census_employee.nil?
              census_employee=employee_role.census_employee
              if census_employee.benefit_group_assignments.exists?
                   benefit_group_assignments=census_employee.benefit_group_assignments
                   benefit_group_assignments.each do |benefit_group_assignment|
                     if benefit_group_assignment.aasm_state=="coverage_waived"
                         unless benefit_group_assignment.hbx_enrollments.nil?
                           benefit_group_assignment.hbx_enrollments.each do |hbx_enrollment|
                             if hbx_enrollment.aasm_state=="auto_renewing"
                               total_count=total_count+1
                             end
                         end
                     end
                   end
              end
            end
        end
        total_count=total_count+1
      end
      #next check has hbx_enrollment with auto_renewing
    end
    end

    puts "There are #{total_count} ee with coverage waived benefit group assignment and associated to an enrollment in the auto_renewal state"
  end
end