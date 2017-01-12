namespace :update_enroll do
  desc "find EE with coverage_waived benefit group assignment and associated to an enrollment in the auto-renewal state"
  task :ee_with_waived_bga_and_autorenewal_enrollment => :environment do
    total_count = 0
    census_employees=CensusEmployee.waived.linked.all

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/EE_autorenew_data_clearnup_list.csv"
    field_names  = %w(
          hbx_id
          first_name
          last_name
          employer_legal_name
          employer_fein,
          employer_profile_dba
          benefit_group_assignments_id
          employer_profile_aasm_state
          waiver_submission_date
        )

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      census_employees.each do |census_employee|
        person=census_employee.try(:employee_role).try(:person)
        benefit_group_assignments=census_employee.try(:benefit_group_assignments).detect { |assignment| assignment.aasm_state== "coverage_waived" }.to_a

        benefit_group_assignments.each do |benefit_group_assignment|

          benefit_group_assignment.hbx_enrollments.each do |hbx_enrollment|
            unless HbxEnrollment::TERMINATED_STATUSES.include?(hbx_enrollment.aasm_state)
              unless person.nil?
                csv << [
                    person.hbx_id,
                    person.first_name,
                    person.last_name,
                    census_employee.employer_profile.legal_name,
                    census_employee.employer_profile.fein,
                    census_employee.employer_profile.dba,
                    benefit_group_assignment.id,
                    census_employee.employer_profile.aasm_state,
                    hbx_enrollment.submitted_at
                ]
                total_count=total_count+1
              end
        end
      end
    end
      end
      puts "There are #{total_count} EE such that benefit group assignment is currently in the coverage_waived state and the person is associated to an enrollment in any state other than canceled."
    end
  end
end
