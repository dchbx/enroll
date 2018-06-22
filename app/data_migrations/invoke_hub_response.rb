require File.join(Rails.root, "lib/mongoid_migration_task")
class InvokeHubResponse < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(:hbx_id => ENV['hbx_id']).first
      if person.present?
        consumer_role = person.consumer_role
        if consumer_role.nil?
          puts "Consumer role not found with hbx id #{ENV['hbx_id']}"
        else
          #Invoking Hub Response
          puts "Invoking HUB Response" unless Rails.env.test?
          verification_attribute = consumer_role.verification_attr
          if consumer_role.redetermine_verification!(verification_attribute)
            puts "Invoked Hub Response succesfully." unless Rails.env.test?
          end
        end
      else
        puts "No Person found with HBX ID #{ENV['hbx_id']}" unless Rails.env.test?
      end
    rescue => e
      puts "#{e}"
    end
  end
end