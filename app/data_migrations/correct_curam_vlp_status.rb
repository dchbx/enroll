require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectCuramVlpStatus < MongoidMigrationTask
  def get_people
    Person.where(
                 'consumer_role.lawful_presence_determination.vlp_authority' => 'curam',
                 "consumer_role.lawful_presence_determination.ssa_responses.received_at" => {
                   "$gte" => Time.mktime(2016, 7, 5,6,0,0)
                 }
                )
  end

  def update_person(person)
    begin
      person.consumer_role.lawful_presence_determination.update_attributes!(:aasm_state => "verification_successful")
      person.consumer_role.update_attributes!(:lawful_presence_update_reason => {:update_reason => "user in curam",
                                                                                :update_comment => "fix data migration",
                                                                                :v_type => "any"})
      person.consumer_role.aasm_state = "fully_verified"
      if person.ssn
        person.consumer_role.ssn_validation = "valid"
        person.consumer_role.ssn_update_reason = "user in curam"
      end
      person.save!
    rescue => e
      puts "Error for Person id: #{person.id}. Error: #{e.message}"
    end
  end

  def migrate
    people_to_fix = get_people
    people_to_fix.each do |person|
      update_person(person)
    end
  end
end
