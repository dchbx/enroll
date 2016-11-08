require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employee terminations by employer profile and date range"
    task :employee_terminations => :environment do

      census_employees = CensusEmployee.unscoped.terminated.where(:employment_terminated_on.gte => (date_start = Date.new(2015,10,1)))

      field_names  = %w(
          employer_name last_name first_name ssn dob aasm_state hired_on employment_terminated_on updated_at
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

      puts "For period #{date_start} - #{Date.today}, #{processed_count} employee terminations output to file: #{file_name}"
    end
  end
end