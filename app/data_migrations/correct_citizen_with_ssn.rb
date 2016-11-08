require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectCitizenStatus < MongoidMigrationTask
  def get_people
    Person.where("consumer_role.lawful_presence_determination.ssa_responses" =>
                     { "$elemMatch" =>
                           {"received_at" =>
                                {"$gte" => Time.mktime(2016,7,5,8,0,0), "$lte" => Time.mktime(2016,7,7,0,0,0) }}},
                 "consumer_role.lawful_presence_determination.vlp_authority" => {"$ne" => "curam"},
                 "consumer_role.lawful_presence_determination.citizen_status" => "us_citizen",
                 "encrypted_ssn" => {"$ne" => nil})
  end

  def move_to_pending_ssa(person)
    begin
      person.consumer_role.aasm_state = "ssa_pending"
      person.save!
    rescue => e
      puts "Error for Person id: #{person.id}. Error: #{e.message}"
    end
  end

  def get_response_doc(person)
    person.consumer_role.lawful_presence_determination.ssa_responses.select do |sa|
      sa.received_at >= Time.mktime(2016,7,5,8,0,0)
    end.sort_by(&:received_at).last
  end

  def get_previous_response(person)
    person.consumer_role.lawful_presence_determination.ssa_responses.select do |sa|
      sa.received_at < Time.mktime(2016,7,5,8,0,0)
    end.sort_by(&:received_at).last
  end

  def parse_payload(response_doc)
    doc = Nokogiri::XML(response_doc.body)
    ssn_node = doc.at_xpath("//ns1:ssn_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"})
    return([false, false]) unless ssn_node
    ssn_valid = (ssn_node.content.downcase.strip == "true")
    return([false, false]) unless ssn_valid
    citizenship_node = doc.at_xpath("//ns1:citizenship_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"})
    return([true, false]) unless citizenship_node
    citizenship_valid = citizenship_node.content.strip.downcase == "true"
    [true, citizenship_valid]
  end

  def parse_ssa_response(person)
    response_doc = get_response_doc(person)
    ssn_response, citizenship_response = parse_payload(response_doc)
    if ssn_response
      if citizenship_response
        person.consumer_role.ssn_valid_citizenship_valid!(args(response_doc))
      else
        if get_previous_response(person)
          check_previous_response(person)
        else
          person.consumer_role.ssn_valid_citizenship_invalid!(args(response_doc))
        end
      end
    else
      if get_previous_response(person)
        check_previous_response(person)
      else
        person.consumer_role.ssn_invalid!(args(response_doc))
      end
    end
  end

  def check_previous_response(person)
    response_doc = get_previous_response(person)
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

  def args(response_doc)
    OpenStruct.new(:determined_at => response_doc.received_at, :vlp_authority => 'ssa')
  end
end
