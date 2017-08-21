require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdatingPersonSsn< MongoidMigrationTask
  def migrate
    hbx_id_1=ENV['hbx_id_1']
    person_ssn=ENV['person_ssn']
    person1 = Person.where(hbx_id:hbx_id_1).first
    if person1.nil?
      puts "No person found with hbx_id #{hbx_id_1}" unless Rails.env.test?
      else
        person1.update_attributes(ssn: person_ssn)
      end
  end
end