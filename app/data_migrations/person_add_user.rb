require File.join(Rails.root, "lib/mongoid_migration_task")

class PersonAddUser < MongoidMigrationTask
  def migrate
    user = User.where(email:ENV['email']).first
    person = Person.where(hbx_id:ENV['hbx_id']).first
    person.update(user_id:user.id)
  end
end
