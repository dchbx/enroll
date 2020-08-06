# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectNotLawfullyCitizenStatus < MongoidMigrationTask

  def get_families
    people_ids = Person.where({ :consumer_role => {"$exists" => true},
                                :"consumer_role.aasm_state" => {'$nin' => ['unverified', 'fully_verified']},
                                :"consumer_role.lawful_presence_determination.citizen_status" => {'$in' => ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION} }).map(&:id)
    Family.where("family_members.person_id" => {"$in" => people_ids})
  end

  def get_enrollments(family)
    family.active_household.hbx_enrollments.individual_market.active.enrolled_and_renewing
  end

  def get_members(enrollment)
    enrollment.hbx_enrollment_members.flat_map(&:person)
  end

  def update_citizen_status_not_lawfully_present(enrollment)
    people = get_members(enrollment)
    people.each do |person|
      old_status = person.citizen_status
      if person.verification_types.active.map(&:type_name).include?('Immigration status') && ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.include?(person.citizen_status)
        lpd(person).update_attributes!(:citizen_status => 'alien_lawfully_present')
        puts "Person HBX_ID: #{person.hbx_id} citizen status was changed from #{old_status} to ==> #{person.citizen_status}" unless Rails.env.test?
      end
    end
  end

  def lpd(person)
    person.try(:consumer_role).try(:lawful_presence_determination)
  end

  def migrate
    families = get_families
    families.each do |family|

      enrollments = get_enrollments(family)
      enrollments.each do |enrollment|
        update_citizen_status_not_lawfully_present(enrollment)
      end
    rescue StandardError => e
      puts "Issue migrating, #{e}"

    end
  end

end
