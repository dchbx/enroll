require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveUserRecord < MongoidMigrationTask

  def migrate
	  person = Person.where(hbx_id: ENV['hbx_id'])
	   if person.size !=1
	     puts 'Issues with hbx_id'
	     return
	   end
	   person.first.user.destroy
	   puts "Removed Person's user record with hbx_id: #{ENV['hbx_id']}" unless Rails.env.test?
  end
end