# Report: Rake task to find employee account satisfying:
#the census employee has been terminated by the employer
#the employee has ER-sponsered enrollment not in terminated or cancelled state
#the date of termination is before 10/31/2016
require 'csv'
namespace :report do
  namespace :user_account do
    desc "List of terminated employee with active_enrollment"
    task :employee_list => :environment do
      census_employees = CensusEmployee.linked.where(aasm_state: "employment_terminated",employee_role_id: {:$exists => true}).all
      field_names  = %w(
               census_employee_hbx_id
               first_name
               last_name
               employer_fein
               employer_legalname
               employer_dba
               census_employee_dot
               er_sponsered_enrollment_hbx_id
               enrollment_state
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/terminated_ee_with_active_enrollment.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        census_employees.each do |census_employee|
          if census_employee.employment_terminated_on<TimeKeeper.date_of_record
            employer=census_employee.employer_profile
            temp = Maybe.new(census_employee)
            person=temp.employee_role.person.extract_value
            #person=census_employee.try(:employee_roles).first.try(:person)
            benefit_group_assignments=census_employee.benefit_group_assignments
            #terminate_state=HbxEnrollment::TERMINATED_STATUSES+HbxEnrollment::CANCELED_STATUSES
            active_state=HbxEnrollment::ENROLLED_STATUSES
            benefit_group_assignments.each do |benefit_group_assignment|
              benefit_group_assignment.hbx_enrollments.each do |enrollment|
                termination_verify=(active_state.include?enrollment.aasm_state)
                employer_sponsor_verify=(enrollment.kind=="employer_sponsored")
                if person&&employer_sponsor_verify&& termination_verify
                    csv << [
                      person.hbx_id,
                      person.first_name,
                      person.last_name,
                      employer.fein,
                      employer.legal_name,
                      employer.dba,
                      census_employee.employment_terminated_on,
                      enrollment.hbx_id,
                      enrollment.aasm_state
                    ]
                    processed_count += 1
                end
             end
            end
          end
          #puts "Total employee with terminated census employee and non-terminatead hbx_enrollment count #{processed_count}" unless Rails.env == 'test'
        end
      end
    end
  end
end
