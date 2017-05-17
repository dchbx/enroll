require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeBrokerNpn < MongoidMigrationTask
  def migrate
    person_hbx_id = ENV['person_hbx_id']
    npn = ENV['new_npn']
    person = Person.where(hbx_id:person_hbx_id).first
    if person.nil?
      puts "No person was found with given hbx_id" unless Rails.env.test?
    else
      broker_role = person.broker_role
      if broker_role.nil?
        puts "No broker role was found with given hbx_id" unless Rails.env.test?
      else
       broker_role.update_attributes(npn:npn)
        puts "update the npn of person #{person_hbx_id}" unless Rails.env.test?
      end
    end
  end
end
