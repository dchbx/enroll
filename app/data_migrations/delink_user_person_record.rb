require File.join(Rails.root, "lib/mongoid_migration_task")

class DelinkUserPersonRecord < MongoidMigrationTask
  def migrate
    hbx_id=ENV['hbx_id']
    person=Person.where(hbx_id: hbx_id).first
    if person.present?
       person.unset(:user_id)
       person.save!
    else 
      puts "Person not found for hbx_id #{hbx_id}"
    end   
  end
end