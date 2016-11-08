require File.join(Rails.root, "lib/mongoid_migration_task")

class DeactivateConsumerRole < MongoidMigrationTask
	def migrate
		role = Person.where(hbx_id: ENV['hbx_id']).first.consumer_role
		role.is_active = false
		role.save
	end
end

