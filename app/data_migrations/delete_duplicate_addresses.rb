# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteDuplicateAddresses < MongoidMigrationTask

  def fetch_duplicate_address_ids(person)
    person.addresses.combination(2).inject([]) do |address_ids, pair|
      address_ids << pair.second.id if pair.first.matches_addresses?(pair.second)
      address_ids
    end
  end

  def migrate
    hbx_id = ENV['person_hbx_id']
    person = Person.all.by_hbx_id(hbx_id).first

    if person.nil?
      puts "Unable to find any person record with the given hbx_id: #{hbx_id}" unless Rails.env.test?
      return
    end

    fetch_duplicate_address_ids(person).each do |address_id|
      address = person.addresses.find(address_id.to_s)
      address.delete
    end
  rescue StandardError => e
    puts e.message unless Rails.env.test?
  end
end
