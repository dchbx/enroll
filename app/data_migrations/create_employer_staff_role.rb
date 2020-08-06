# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateEmployerStaffRole < MongoidMigrationTask
  def migrate
    person_hbx_id = ENV['person_hbx_id']
    employer_profile_id = ENV['employer_profile_id']
    begin
      person = Person.where(hbx_id: person_hbx_id).first
      current_user = person.user if person
      if current_user
        person.employer_staff_roles << ::EmployerStaffRole.new(person: person, benefit_sponsor_employer_profile_id: employer_profile_id, is_owner: true, aasm_state: 'is_active')
        current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
        current_user.save!
        person.save!
      else
        puts "User cannot be found for the given person, cannot process" unless Rails.env.test?
      end
    rescue StandardError => e
      puts "Cannot process the given person, error: #{e}, backtrace: #{e.backtrace}" unless Rails.env.test?
    end
  end
end
