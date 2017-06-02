
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveHbxId< MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['person_hbx_id']
      person = Person.where(hbx_id:hbx_id).first
      if person.nil?
        puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
      else
        person.unset(:hbx_id)
        puts "Remove Hbx Id: #{hbx_id} from enroll app " unless Rails.env.test?
      end
    rescue => e
      puts "#{e}"
    end
  end
end