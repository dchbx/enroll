
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeSuffixPerson < MongoidMigrationTask
  def migrate
    puts "updating person suffix" unless Rails.env.test?
    hbx_ids=ENV['hbx_ids'].split(' ').uniq
    hbx_ids.each do |hbx_id|
      person = Person.where(hbx_id: hbx_id).first
      if person.present?
        person.update_attributes(name_sfx: "")
        person.save
      else
        puts "Person not found for hbx_id #{hbx_id}"
      end
    end
  end
end
