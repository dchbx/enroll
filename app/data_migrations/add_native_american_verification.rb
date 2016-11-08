require File.join(Rails.root, "lib/mongoid_migration_task")

class AddNativeVerification < MongoidMigrationTask
  def get_people
    Person.where("consumer_role" => {"$exists" => true})
  end

  def migrate
    people_to_fix = get_people
    people_to_fix.each do |person|
      begin
        if person.consumer_role.try(:lawful_presence_determination).try(:vlp_authority) == "curam"
          person.consumer_role.native_validation = "valid"
        else
          person.consumer_role.ensure_validation_states
        end
        person.save
      rescue => e
        $stderr.puts "Issue migrating person: #{person.full_name}, #{person.hbx_id}, #{person.id}, #{e.message}" unless Rails.env.test?
      end
    end
  end
end