# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateVerificationTypes < MongoidMigrationTask
  def get_people
    Person.where("consumer_role.aasm_state" => {'$in' => ["fully_verified", "sci_verified"]}, "consumer_role.is_state_resident" => nil)
  end

  def migrate
    people_to_fix = get_people
    people_to_fix.each_with_index do |person, i|

      update_local_residency(person, "datamigration")
      puts "#{i} Updating... #{person.id}" unless Rails.env.test?
    rescue StandardError
      warn "Issue migrating person: #{person.fullname}, #{person.hbx_id}, #{person.id}" unless Rails.env.test?

    end
  end

  def update_local_residency(person, update_reason)
    local_state = person.consumer_role.local_residency_validation == "attested" ? "attested" : "valid"
    person.consumer_role.update_attributes(:is_state_resident => true, :residency_update_reason => update_reason, :residency_determined_at => Time.now, :local_residency_validation => local_state)
  end
end
