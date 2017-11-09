require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveHbxIdFromPerson < MongoidMigrationTask
  def migrate
    begin
      p1 = Person.where(hbx_id:ENV['p1_id']).first
      p2 = Person.where(hbx_id:ENV['p2_id']).first
      
      if p1.nil?
        puts "No person found for p1"
      elsif p2.nil?
        puts "No person found for p2"
      else
        p1.update(hbx_id:ENV['hbx'])
        p2.update(hbx_id:ENV['p1_id'])
      end
      
    end
  end
end