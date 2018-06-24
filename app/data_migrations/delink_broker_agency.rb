require File.join(Rails.root, "lib/mongoid_migration_task")
class DelinkBrokerAgency< MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    person = Person.where(hbx_id:hbx_id)
    if person.size == 0
      puts "No person found with the given hbx_id" unless Rails.env.test?
      return
    else
      primary_family = person.first.primary_family
      if primary_family.present?
        primary_family.broker_agency_accounts = []
        primary_family.save
      else
        puts "No primary family found" unless Rails.env.test?
      end
    end
  end
end