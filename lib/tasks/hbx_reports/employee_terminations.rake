require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee terminations by employer profile and date range"
    task :employee_terminations => :environment do
      today = TimeKeeper.date_of_record
      yesterday = today - 1.day

      # find census_employees who terminated by their employer
      census_employees = CensusEmployee.unscoped.where(:aasm_state.in => ['employee_termination_pending', 'employment_terminated']).
                          where(:employment_terminated_on.gte => yesterday).
                          where(:employment_terminated_on.lt => today)

      # find census_employees who terminate their hbx_enrollment by themselves
      families = Family.where(:"households.hbx_enrollments" =>{ :$elemMatch => {:"aasm_state".in => ["coverage_terminated", "coverage_termination_pending"],
                                                                                :"termination_submitted_on" => (yesterday..today)}})
      ces = families.inject([]) do |employees, family|
        terminated_enrollments = family.latest_household.hbx_enrollments.
                any_in(aasm_state: ['coverage_terminated', 'coverage_termination_pending']).
                where(:"termination_submitted_on" => { "$gte" => yesterday, "$lt" => today})
        employees += terminated_enrollments.map(&:benefit_group_assignment).compact.map(&:census_employee).uniq
      end

      field_names  = %w(
          employer_name last_name first_name ssn dob aasm_state hired_on employment_terminated_on updated_at termination_source
        )

      processed_count = 0
      file_name = "#{Rails.root}/public/employee_terminations.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        census_employees.each do |census_employee|
          last_name                 = census_employee.last_name
          first_name                = census_employee.first_name
          ssn                       = census_employee.ssn
          dob                       = census_employee.dob
          hired_on                  = census_employee.hired_on
          employment_terminated_on  = census_employee.employment_terminated_on
          aasm_state                = census_employee.aasm_state
          updated_at                = census_employee.updated_at.localtime
          termination_source        = "employer roster termination"

          employer_name = census_employee.employer_profile.organization.legal_name

          # Only include ERs active on the HBX
          active_states = %w(registered eligible binder_paid enrolled suspended)

          if active_states.include? census_employee.employer_profile.aasm_state
            csv << field_names.map do |field_name|
              if eval(field_name).to_s.blank? || field_name != "ssn"
                eval("#{field_name}")
              elsif field_name == "ssn"
                '="' + eval(field_name) + '"'
              end
            end
            processed_count += 1
          end
        end

        ces.each do |census_employee|
          last_name                 = census_employee.last_name
          first_name                = census_employee.first_name
          ssn                       = census_employee.ssn
          dob                       = census_employee.dob
          hired_on                  = census_employee.hired_on
          employment_terminated_on  = census_employee.try(:active_benefit_group_assignment).try(:hbx_enrollment).try(:terminated_on)
          aasm_state                = census_employee.aasm_state
          updated_at                = census_employee.updated_at.localtime
          termination_source        = "employee initiated termination"

          employer_name = census_employee.employer_profile.organization.legal_name

          # Only include ERs active on the HBX
          active_states = %w(registered eligible binder_paid enrolled suspended)

          if active_states.include? census_employee.employer_profile.aasm_state
            csv << field_names.map do |field_name|
              if eval(field_name).to_s.blank? || field_name != "ssn"
                eval("#{field_name}")
              elsif field_name == "ssn"
                '="' + eval(field_name) + '"'
              end
            end
            processed_count += 1
          end
        end
      end

      puts "For period #{yesterday} - #{today}, #{processed_count} employee terminations output to file: #{file_name}"
    end
  end
end
