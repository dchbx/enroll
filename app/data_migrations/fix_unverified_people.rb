require File.join(Rails.root, "lib/mongoid_migration_task")

class FixUnverifiedPeople < MongoidMigrationTask
  def migrate
    people = get_unverified_people
    people.each do |person|
      begin
        if person.ssn || person.consumer_role.is_native?
          move_to_pending_ssa(person)
          person.reload
          parse_ssa_response(person)
          puts "Person with ssa response moved : #{person.full_name}, #{person.hbx_id}" unless Rails.env.test?
        else
          move_to_pending_dhs(person)
          person.reload
          parse_dhs_response(person)
          puts "Person with dhs response moved : #{person.full_name}, #{person.hbx_id} " unless Rails.env.test?
        end
      rescue
        $stderr.puts "Issue migrating person: #{person.full_name}, #{person.hbx_id}" unless Rails.env.test?
      end
    end
  end

  def move_to_pending_ssa(person)
    begin
      person.consumer_role.aasm_state = "ssa_pending"
      person.save!
    rescue => e
      puts "Error for Person id: #{person.id}. Error: #{e.message}"
    end
  end

  def move_to_pending_dhs(person)
    begin
      person.consumer_role.aasm_state = "dhs_pending"
      person.save!
    rescue => e
      puts "Error for Person id: #{person.id}. Error: #{e.message}"
    end
  end

  def get_unverified_people
    Person.where({'$and' => [
        {"consumer_role.aasm_state"=>"unverified"},
        {'$and' => [
            { '$or' => [
                {"consumer_role.lawful_presence_determination.ssa_responses" => {'$exists' => true}},
                {"consumer_role.lawful_presence_determination.vlp_responses" => {'$exists' => true}}
            ]},

            {"consumer_role.ssn_validation" => "pending" }

        ]}
    ]})
  end

  def parse_ssa_response(person)
    response = ssa_response(person)
    xml_hash = ssa_xml_to_hash(response.body)
    update_ssa_consumer_role(person.consumer_role, xml_hash)
  end

  def parse_dhs_response(person)
    response = dhs_response(person)
    xml_hash = dhs_xml_to_hash(response)
    update_dhs_consumer_role(person.consumer_role, xml_hash)
  end

  def update_ssa_consumer_role(consumer_role, xml_hash)
    args = OpenStruct.new

    if xml_hash[:ssn_verification_failed].eql?("true")
      args.determined_at = Time.now
      args.vlp_authority = 'hbx'
      consumer_role.ssn_invalid!(args)
    elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("true")
      args.determined_at = Time.now
      args.vlp_authority = 'hbx'
      args.citizenship_result = ::ConsumerRole::US_CITIZEN_STATUS
      consumer_role.ssn_valid_citizenship_valid!(args)
    elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("false")
      args.determined_at = Time.now
      args.vlp_authority = 'hbx'
      args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
      consumer_role.ssn_valid_citizenship_invalid!(args)
    end
    consumer_role.save
  end

  def update_dhs_consumer_role(consumer_role, xml_hash)
    args = OpenStruct.new
    if xml_hash[:lawful_presence_indeterminate].present?
      args.determined_at = Time.now
      args.vlp_authority = 'hbx'
      consumer_role.fail_dhs!(args)
    elsif xml_hash[:lawful_presence_determination].present? && xml_hash[:lawful_presence_determination][:response_code].eql?("lawfully_present")
      args.determined_at = Time.now
      args.vlp_authority = 'hbx'
      args.citizenship_result = get_citizen_status(xml_hash[:lawful_presence_determination][:legal_status])
      consumer_role.pass_dhs!(args)
    elsif xml_hash[:lawful_presence_determination].present? && xml_hash[:lawful_presence_determination][:response_code].eql?("not_lawfully_present")
      args.determined_at = Time.now
      args.vlp_authority = 'hbx'
      args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
      consumer_role.fail_dhs!(args)
    end
    consumer_role.save
  end


  def ssa_xml_to_hash(xml)
    Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml).to_hash
  end

  def dhs_xml_to_hash(xml)
    Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(xml).to_hash
  end

  def ssa_response(person)
    person.consumer_role.lawful_presence_determination.ssa_responses.sort_by(&:received_at).last
  end

  def dhs_response(person)
    person.consumer_role.lawful_presence_determination.vlp_responses.sort_by(&:received_at).last.try(:body)
  end
end
