# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeHbxId < MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    new_hbx_id = ENV['new_hbx_id']
    person = Person.where(hbx_id: hbx_id).first
    if person.nil?
      puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
    else
      person.update_attributes(hbx_id: new_hbx_id)
      puts "Change Hbx Id: #{hbx_id} to #{new_hbx_id} " unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.to_s
  end
end