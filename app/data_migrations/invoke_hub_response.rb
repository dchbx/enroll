# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class InvokeHubResponse < MongoidMigrationTask
  def migrate
    person = Person.where(:hbx_id => ENV['hbx_id']).first
    if person.present?
      consumer_role = person.consumer_role
      if consumer_role.nil?
        puts "Consumer role not found with hbx id #{ENV['hbx_id']}"
      else
        #Invoking Hub Response
        puts "Invoking HUB Response" unless Rails.env.test?
        verification_attribute = consumer_role.verification_attr
        puts "Invoked Hub Response succesfully." if consumer_role.redetermine_verification!(verification_attribute) && !Rails.env.test?
      end
    else
      puts "No Person found with HBX ID #{ENV['hbx_id']}" unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.to_s
  end
end