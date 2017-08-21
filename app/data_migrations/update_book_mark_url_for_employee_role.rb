require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBookMarkUrlForEmployeerole < MongoidMigrationTask
  def migrate
  	begin
      id = ENV["employee_role_id"].to_s
      bookmark_url = ENV["bookmark_url"]
	  employee_role = EmployeeRole.find(id)
	  employee_role.update_attributes(bookmark_url: bookmark_url)
      puts "Chnage book mark url for Employee Role:#{ENV["employee_role_id"]} to URL:#{ENV["bookmark_url"]}" unless Rails.env.test?
    rescue => e   
      puts "#{e}"
    end
  end
end