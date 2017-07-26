require File.join(Rails.root, "lib/mongoid_migration_task")
class DisablePersonAccount< MongoidMigrationTask
  def migrate
    hbx_id = ENV['hbx_id']
    person = Person.where(hbx_id:hbx_id).first
    if person.nil?
      puts "No person was found by the given fein"
    else
      person.update_attributes!(is_active: false, is_disabled: true)
      puts "Disable person with hbx_id #{hbx_id}" unless Rails.env.test?
    end
  end
end
