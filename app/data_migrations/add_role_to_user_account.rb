require File.join(Rails.root, "lib/mongoid_migration_task")
class AddRoleToUserAccount< MongoidMigrationTask
  def migrate
    user_id = ENV['user_id']
    new_role = ENV['new_role']
    user = User.where(id:user_id).first
    if user.nil?
      puts "No user was found with id #{user_id}" unless Rails.env.test?
      return
    end
    user.roles << new_role
    user.save!
    puts "Add #{new_role} to user with id #{user_id}" unless Rails.env.test?
  end
end
