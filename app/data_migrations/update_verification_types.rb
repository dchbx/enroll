require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateVerificationTypes < MongoidMigrationTask
  def get_people
    Person.where("consumer_role.aasm_state" => "fully_verified")
  end

  def migrate
    people_to_fix = get_people
    people_to_fix.each do |person|
      begin
        person.consumer_role.update_all_verification_types unless person.consumer_role.all_types_verified?
      rescue
        $stderr.puts "Issue migrating person: #{person.fullname}, #{person.hbx_id}, #{person.id}"
      end
    end
  end
end
