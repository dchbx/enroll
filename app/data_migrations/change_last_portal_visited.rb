require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeLastPortalVisited < MongoidMigrationTask
  def migrate
    begin
      user_oimid = ENV['user_oimid']
      new_url = ENV['new_url']
      user = User.where(oim_id:user_oimid).first
      if user.nil?
        puts "No user was found with given oim_id" unless Rails.env.test?
      else
        user.update_attributes(last_portal_visited: new_url)
        puts "update the user last portal visited to #{new_url}" unless Rails.env.test?
      end
    rescue => e
      puts "#{e}"
    end
  end
end
