require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfileId < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id'])
    if person.size != 1
      raise "Invalid Hbx Id"
    end
     person.first.broker_agency_staff_roles.first.update_attributes!(broker_agency_profile_id: person.first.broker_role.broker_agency_profile_id)
     puts "Updating broker agency profile id for Person with hbx id: #{ENV['hbx_id']} " unless Rails.env.test?
   end
end
