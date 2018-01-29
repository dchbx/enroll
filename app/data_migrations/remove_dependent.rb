require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDependent < MongoidMigrationTask
  def migrate
    begin
      id = ENV["family_member_id"].to_s
      family_member = FamilyMember.find(id)
      if family_member.nil?
        puts "No family member found" unless Rails.env.test?
      else
        family_member.destroy!
        puts "remove duplicate dependent with family member id: #{family_member.id}" unless Rails.env.test?
      end   
    rescue Exception => e
      puts e.message
    end
  end
end


