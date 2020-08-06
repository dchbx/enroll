# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeGeneralAgencyStaffRole < MongoidMigrationTask
  def migrate
    incorrect_person_hbx_id = ENV['incorrect_person_hbx_id']
    correct_person_hbx_id = ENV['correct_person_hbx_id']

    if incorrect_person_hbx_id && correct_person_hbx_id
      incorrect_person = Person.where(hbx_id: incorrect_person_hbx_id).first
      if incorrect_person.nil?
        puts "No person was found with given hbx_id" unless Rails.env.test?
      else
        gen_staff_role = incorrect_person.general_agency_staff_roles.first
        correct_person = Person.where(hbx_id: correct_person_hbx_id).first
        correct_person.general_agency_staff_roles << GeneralAgencyStaffRole.new(
          npn: gen_staff_role.npn,
          general_agency_profile_id: gen_staff_role.general_agency_profile_id,
          aasm_state: gen_staff_role.aasm_state
        )
        correct_person.save!
        Invitation.invite_general_agency_staff!(correct_person.general_agency_staff_roles.first)
        puts "Correct Person is Assigned the GA Staff Role" unless Rails.env.test?
        incorrect_person.general_agency_staff_roles.first.destroy!
        incorrect_person.save!
      end
    else
      puts "Please pass incorrect and correct hbx_ids as respective arguments" unless Rails.env.test?
    end
  end
end