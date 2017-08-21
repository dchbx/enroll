require File.join(Rails.root, "lib/mongoid_migration_task")

class RemovePersonSsn< MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument
    hbx_id = ENV['person_hbx_id']
    person = Person.where(hbx_id:hbx_id).first
    if person.nil?
      puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
    else
      person.unset(:encrypted_ssn)
      puts "Remove ssn from person with hbx_id  #{hbx_id}" unless Rails.env.test?
    end
  end
end