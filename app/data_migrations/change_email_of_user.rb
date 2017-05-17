require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeEmailOfUser < MongoidMigrationTask
  def migrate
    user_oimid = ENV['user_oimid']
    new_email = ENV['new_email']
    user = User.where(oim_id:user_oimid).first
    if user.nil?
      puts "No user was found with given oim_id" unless Rails.env.test?
    else
      user.update_attributes(email:new_email)
      puts "update the user email to #{new_email}" unless Rails.env.test?
    end
  end
end
