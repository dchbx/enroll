# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfileId < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id'])
    raise "Invalid Hbx Id" if person.size != 1
    person.first.broker_agency_staff_roles.first.update_attributes!(broker_agency_profile_id: person.first.broker_role.broker_agency_profile_id)
    puts "Updating broker agency profile id for Person with hbx id: #{ENV['hbx_id']} " unless Rails.env.test?
  end
end
