require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfileLegalName < MongoidMigrationTask
  def migrate
    o = Organization.where(fein: ENV['fein']).first
    if o.nil?
      puts 'No organization was found with given legal name' unless Rails.env.test?
    end
    return unless o.broker_agency_profile
    o.update_attributes(legal_name:ENV['new_legal_name'])
    puts "The legal name of broker agency profile has been changed to #{ENV['new_legal_name']}" unless Rails.env.test?
  end
end
