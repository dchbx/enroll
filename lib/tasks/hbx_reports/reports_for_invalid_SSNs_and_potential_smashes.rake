# Run the following rake task: RAILS_ENV=production bundle exec rake reports:people_with_invalid_SSN_and_multiple_families
require 'csv'
namespace :reports do
  desc "Users with Invalid SSN's & people having more than 1 family"
  task :people_with_invalid_SSN_and_multiple_families => :environment do
    count = 0
    size = 0

    field_names  = %w(
      HBX_ID
      FirstName
      LastName
      DOB
      SSN
      Is_Primary
      Has_Employee_Role
      Has_IVL_Role
      Has_Employer_Role
    )

    file_name = "#{Rails.root}/public/people_with_invalid_SSNs.csv"
    file_name2 = "#{Rails.root}/public/people_having_multiple_families.csv"

    def is_primary?(person)
      person.primary_family.present?
    end

    def has_employee_role?(person)
      person.employee_roles?
    end

    def has_ivl_role?(person)
      person.consumer_role?
    end

    def has_employer_staff_role?(person)
      person.employer_staff_roles?
    end

    persons = Person.where(:"encrypted_ssn".ne => nil)

    CSV.open(file_name, "w", force_quotes: true) do |row|
      row << field_names
      persons.each do |person|
        begin
          if person.send(:is_ssn_composition_correct?)
            count = count + 1
            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              person.dob,
              person.ssn,
              is_primary?(person),
              has_employee_role?(person),
              has_ivl_role?(person),
              has_employer_staff_role?(person)
            ]
          end
        rescue => e
          puts "Bad record: Exception: #{e}"
        end
      end
      puts "People with invalid SSN count: #{count}"
    end

    CSV.open(file_name2, "w", force_quotes: true) do |row|
      row << field_names
      Person.all.each do |person|
        begin
          if person.families.size > 1
            size = size + 1
            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              person.dob,
              person.ssn,
              is_primary?(person),
              has_employee_role?(person),
              has_ivl_role?(person),
              has_employer_staff_role?(person)
            ]
          end
        rescue => e
          puts "Bad record: Exception: #{e}"
        end
      end
      puts "People with multiple families size: #{size}"
    end
  end
end