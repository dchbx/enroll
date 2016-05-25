namespace :migrations do

  desc "Make benefit group assignment linked to coverage as default benefit group assignment"
  task :enable_benefit_group_assignments_with_coverage => [:environment] do
    count = 0
    orgs = Organization.exists(:employer_profile => true)    
    orgs.each do |org|
      employer_profile = org.employer_profile
      
      census_employees = employer_profile.census_employees
      next if census_employees.empty?

      plan_year = employer_profile.active_plan_year 
      next if plan_year.blank?

      census_employees.each do |census_employee|
        enrollments = enrollments_for_census_empoyee(plan_year, census_employee)
        assignment_ids = enrollments.map(&:benefit_group_assignment_id).compact.uniq
        next unless assignment_ids.size == 1
        next if assignment_ids.include?(census_employee.active_benefit_group_assignment.try(:_id))
        enrollments.first.benefit_group_assignment.make_active
        puts "Fixed #{census_employee.full_name} under #{employer_profile.legal_name}"
        count += 1
      end
    end
    puts "Fixed #{count} census employees records."
  end

  def enrollments_for_census_empoyee(plan_year, census_employee)
    id_list = plan_year.benefit_groups.collect(&:_id).uniq
    assignment_id_list = census_employee.benefit_group_assignments.where(:"benefit_group_id".in => id_list).map(&:_id).uniq
    families = Family.where(:"households.hbx_enrollments.benefit_group_assignment_id".in => assignment_id_list)
    families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments
            .any_of([HbxEnrollment.enrolled.selector, HbxEnrollment.terminated.selector, HbxEnrollment.waived.selector])
            .where(:benefit_group_id.in => id_list)
            .where(:benefit_group_assignment_id.in => assignment_id_list)
            # .show_enrollments_sans_canceled
    end
  end

  desc "Cleanup benefit group assignments which failed date gaurds"
  task :fix_benefit_group_assigments_with_invalid_dates => :environment do

    orgs = Organization.exists(:employer_profile => true)
    date_gaurds_failed = 0
    invalid_bgsm = 0
    
    puts "found #{orgs.size} employers"

    count = 0
    orgs.each do |org|
      next if ["536002522", "536002523", "536002558"].include?(org.fein)
      
      count += 1
      employer_profile = org.employer_profile
      employer_profile.census_employees.each do |ce|
        ce.benefit_group_assignments.each do |bg_assignment|
          next if bg_assignment.valid?
          invalid_bgsm += 1

          if benefit_group = bg_assignment.benefit_group
            date_range = benefit_group.start_on..benefit_group.end_on
            next if date_range.cover?(bg_assignment.start_on) && (bg_assignment.end_on.blank? || (bg_assignment.end_on.present? && date_range.cover?(bg_assignment.end_on)))

            if !date_range.cover?(bg_assignment.start_on)
              bg_assignment.start_on = date_range.begin
            end

            if bg_assignment.end_on.present? && !date_range.cover?(bg_assignment.end_on)
              bg_assignment.end_on = date_range.end
            end

            bg_assignment.save(:validate => false)
            puts "#{ce.full_name}---#{employer_profile.legal_name}---dates fixed"
          end
        end
      end

      if count % 100 == 0
        puts "processed #{count}"
      end
    end

    puts invalid_bgsm
    puts date_gaurds_failed
  end
end





