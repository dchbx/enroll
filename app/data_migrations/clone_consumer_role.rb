require File.join(Rails.root, "lib/mongoid_migration_task")
class CloneConsumerRole < MongoidMigrationTask
  def migrate
    hbx_id_1=ENV['old_hbx_id']
    hbx_id_2=ENV['new_hbx_id']
    person1 = Person.where(hbx_id:hbx_id_1).first
    person2 = Person.where(hbx_id:hbx_id_2).first
    return puts "No person found with hbx_id #{hbx_id_1}" if person1.nil? && !Rails.env.test?
    return puts "No person found with hbx_id #{hbx_id_2}" if person2.nil? && !Rails.env.test?

    cr=person1.consumer_role
    if cr.nil?
      puts "person with hbx_id  #{hbx_id_1} has no consumer role" unless Rails.env.test?
      return
    end
    person2.consumer_role = cr.dup
    person2.consumer_role.save!
    puts "consumer role to #{hbx_id_2} has been cloned from #{hbx_id_1}" unless Rails.env.test?
  end
end
