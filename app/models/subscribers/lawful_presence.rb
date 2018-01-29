module Subscribers
  class LawfulPresence < ::Acapi::Subscription
    include Acapi::Notifiers
    def self.subscription_details
      ["acapi.info.events.lawful_presence.vlp_verification_response"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringed_key_payload = payload.stringify_keys
        xml = stringed_key_payload['body']
        person_hbx_id = stringed_key_payload['individual_id']
        return_status = stringed_key_payload["return_status"].to_s

        person = find_person(person_hbx_id)
        return if person.nil? || person.consumer_role.nil?

        consumer_role = person.consumer_role
        event_response_record = EventResponse.new({received_at: Time.now, body: xml})
        consumer_role.lawful_presence_determination.vlp_responses << event_response_record
        if consumer_role.person.verification_types.include? "Citizenship"
          type = "Citizenship"
        elsif consumer_role.person.verification_types.include? "Immigration status"
          type = "Immigration status"
        end
        consumer_role.add_type_history_element(verification_type: type,
                                               action: "DHS Hub response",
                                               modifier: "external Hub",
                                               update_reason: "Hub response",
                                               event_response_record_id: event_response_record.id)
        if "503" == return_status
          args = OpenStruct.new
          args.determined_at = Time.now
          args.vlp_authority = 'dhs'
          consumer_role.fail_dhs!(args)
          consumer_role.save      
          return                          
        end 

        xml_hash = xml_to_hash(xml)

        update_consumer_role(consumer_role, xml_hash)
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.vlp_responses", {
          :body => JSON.dump({
            :error => e.inspect,
            :message => e.message,
            :backtrace => e.backtrace
          })})
      end
    end

    def update_consumer_role(consumer_role, xml_hash)
      args = OpenStruct.new
      if xml_hash[:lawful_presence_indeterminate].present?
        args.determined_at = Time.now
        args.vlp_authority = 'dhs'
        consumer_role.fail_dhs!(args)
      elsif xml_hash[:lawful_presence_determination].present? && xml_hash[:lawful_presence_determination][:response_code].eql?("lawfully_present")
        args.determined_at = Time.now
        args.vlp_authority = 'dhs'
        args.citizenship_result = get_citizen_status(xml_hash[:lawful_presence_determination][:legal_status])
        consumer_role.pass_dhs!(args)
      elsif xml_hash[:lawful_presence_determination].present? && xml_hash[:lawful_presence_determination][:response_code].eql?("not_lawfully_present")
        args.determined_at = Time.now
        args.vlp_authority = 'dhs'
        args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
        consumer_role.fail_dhs!(args)
      end
      consumer_role.save
    end

    def get_citizen_status(legal_status)
      return "us_citizen" if legal_status.eql? "citizen"
      return "lawful_permanent_resident" if legal_status.eql? "lawful_permanent_resident"
      return "alien_lawfully_present" if ["asylee", "refugee", "non_immigrant", "application_pending", "student", "asylum_application_pending", "daca" ].include? legal_status
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end
  end
end
