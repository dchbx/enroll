# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdatePersonName < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first
    first_name = ENV['first_name']
    last_name = ENV['last_name']

    if person.nil?
      puts "No person was found by the given hbx_id" unless Rails.env.test?
    else
      person.update_attributes(first_name: first_name, last_name: last_name)
      puts "Updating Person Name " unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.to_s
  end
end
