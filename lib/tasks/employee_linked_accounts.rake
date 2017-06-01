namespace :migrations do
  task :employee_linked_accounts, [:file] => :environment do |task, args|

    file_name = "#{Rails.root}/public/employee_linked_accounts.csv"
    field_names  = %w(
      full_name dob ssn address
    )

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      Person.all_employee_roles.each do |person|
        begin
          if person.has_active_employee_role?
            active_employee_roles = person.active_employee_roles
            active_employee_roles.each do |employee_role|
              census_employee = employee_role.census_employee
              if census_employee.present? && census_employee.aasm_state == "employee_role_linked"
                families = Family.find_all_by_person(person)
                if families.present? && families.size > 1
                  csv << [person.full_name, person.dob, person.ssn, person.contact_addresses.try(:first).try(:full_address)]
                end
              end
            end
          end
        rescue Exception => e
          puts e.message
        end
      end

    end

  end
end