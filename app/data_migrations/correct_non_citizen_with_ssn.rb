require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "app/data_migrations/correct_citizen_with_ssn")

class CorrectNonCitizenStatus < CorrectCitizenStatus
  def get_people
    Person.where("consumer_role.lawful_presence_determination.ssa_responses" =>
                     { "$elemMatch" => {
                         "received_at" => {"$gte" => Time.mktime(2016,7,5,8,0,0), "$lte" => Time.mktime(2016,7,7,0,0,0) }
                     }},
                 "consumer_role.lawful_presence_determination.vlp_authority" => {"$ne" => "curam"},
                 "consumer_role.lawful_presence_determination.citizen_status" => {"$ne" => "us_citizen"},
                 "encrypted_ssn" => {"$ne" => nil})
  end

  def parse_ssa_response(person)
    response_doc = get_response_doc(person)
    ssn_response, citizenship_response = parse_payload(response_doc)
    if ssn_response
      if citizenship_response
        person.consumer_role.ssn_valid_citizenship_valid!(args(response_doc))
      else
        person.consumer_role.ssn_valid_citizenship_invalid!(args(response_doc))
      end
    else
      person.consumer_role.ssn_invalid!(args(response_doc))
    end
  end

  def migrate
    people_to_fix = get_people
    people_to_fix.each do |person|
      begin
        move_to_pending_ssa(person)
        person.reload
        parse_ssa_response(person)
      rescue
        $stderr.puts "Issue migrating person: #{person.fullname}, #{person.hbx_id}, #{person.id}"
      end
    end
  end
end
