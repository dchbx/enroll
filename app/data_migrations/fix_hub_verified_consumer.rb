require File.join(Rails.root, "lib/mongoid_migration_task")

class FixHubVerifiedConsumer < MongoidMigrationTask
  def migrate
    people = get_people
    people.each do |person|
      person.verification_types.each do |v_type|
        if type_verified_by_hub(person, v_type)
          update_verification_type(person, v_type)
          puts "Person TYPE verified person: #{person.id} type: #{v_type}" unless Rails.env.test?
        end
      end
    end
  end

  def update_verification_type(person, v_type)
    case v_type
      when "Social Security Number"
        person.consumer_role.update_attributes(:ssn_validation => "valid",
                                               :ssn_update_reason => "data_fix_hub_response")
      when "American Indian Status"
        person.consumer_role.update_attributes(:native_validation => "valid",
                                               :native_update_reason => "data_fix_hub_response")
      when "DC Residency"
        # handle local residency
      else
        person.consumer_role.lawful_presence_determination.authorize!(person.consumer_role.verification_attr)
        person.consumer_role.update_attributes(:lawful_presence_update_reason =>
                                                   {:v_type => v_type,
                                                    :update_reason => "data_fix_hub_response"
                                                   } )
    end

    if person.all_types_verified? && !person.consumer_role.fully_verified?
      begin
        person.consumer_role.verify_ivl_by_admin
        puts "Person state verified person: #{person.id}" unless Rails.env.test?
      rescue => e
        puts "Issue migrating person #{person.id}" unless Rails.env.test?
      end
    end
  end

  def type_verified_by_hub(person, v_type)
    if v_type == "Social Security Number"
      return true if ssa_response(person) && parse_ssa(ssa_response(person)).first
    else
      return true if ssa_response(person) && parse_ssa(ssa_response(person)).last
      return true if dhs_response(person) && parse_dhs(dhs_response(person)).first == "lawfully present"
    end
    false
  end

  def vlp_resp_to_hash(response)
    Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(this_vlp(response)).to_hash
  end

  def parse_dhs(response)
    return [vlp_resp_to_hash(response)[:lawful_presence_indeterminate][:response_code].split("_").join(" "), "not lawfully present"] if vlp_resp_to_hash(response)[:lawful_presence_indeterminate].present?
    return ["lawfully present", vlp_resp_to_hash(response)[:lawful_presence_determination][:legal_status]] if vlp_resp_to_hash(response)[:lawful_presence_determination].present? && vlp_resp_to_hash(response)[:lawful_presence_determination][:response_code].eql?("lawfully_present")
    ["not lawfully present", "not lawfully present"] if vlp_resp_to_hash(response)[:lawful_presence_determination].present? && vlp_resp_to_hash(response)[:lawful_presence_determination][:response_code].eql?("not_lawfully_present")
  end

  def parse_ssa(ssa_response)
    doc = Nokogiri::XML(ssa_response.body)
    ssn_node = doc.at_xpath("//ns1:ssn_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"})
    return([false, false]) unless ssn_node
    ssn_valid = (ssn_node.content.downcase.strip == "true")
    return([false, false]) unless ssn_valid
    citizenship_node = doc.at_xpath("//ns1:citizenship_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"})
    return([true, false]) unless citizenship_node
    citizenship_valid = citizenship_node.content.strip.downcase == "true"
    [true, citizenship_valid]
  end

  def this_vlp(response)
    Nokogiri::XML(response)
  end

  def get_people
    Person.where({'$or' => [
        {"consumer_role.aasm_state"=>"verification_outstanding"},
        {'$and' => [
            {"consumer_role.aasm_state"=>{'$in' => ["fully_verified", "sci_verified"]}},
            { '$or' => [
                {"consumer_role.lawful_presence_determination.ssa_responses" => {'$exists' => true}},
                {"consumer_role.lawful_presence_determination.vlp_responses" => {'$exists' => true}}
            ]},
            { '$or' => [
                {"consumer_role.ssn_validation" => {'$in' => [
                    "outstanding", "pending"
                ]}},
                {"consumer_role.citizen_status" => {'$in' => [
                    "not_lawfully_present_in_us", "non_native_not_lawfully_present_in_us", "ssn_pass_citizenship_fails_with_SSA", "non_native_citizen"
                ]}}
            ]}
        ]}
    ]})
  end

  def ssa_response(person)
    person.consumer_role.lawful_presence_determination.ssa_responses.sort_by(&:received_at).last
  end

  def dhs_response(person)
    person.consumer_role.lawful_presence_determination.vlp_responses.sort_by(&:received_at).last.try(:body)
  end
end