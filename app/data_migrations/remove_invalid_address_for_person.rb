# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidAddressForPerson < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['person_hbx_id']).first
    address_id = ENV['address_id'].to_s
    raise "Person not found for HBX ID #{ENV['person_hbx_id']}. Please provide valid one" if person.blank?

    address = person.addresses.where(id: address_id).first

    raise "No address record found for the person" if address.blank?

    address.delete
    person.save!
  end
end