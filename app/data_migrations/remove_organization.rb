require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveOrganization < MongoidMigrationTask

  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      puts 'Issues with fein'
      return
    end
    organizations.first.destroy!
    puts "Removed Organization with fein: #{ENV['fein']}" unless Rails.env.test?
  end
end
