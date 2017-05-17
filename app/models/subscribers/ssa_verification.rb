module Subscribers
  class SsaVerification < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.lawful_presence.ssa_verification_response"]
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
        consumer_role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: Time.now, body: xml})

        #TODO change response handler
        if "503" == return_status.to_s
          args = OpenStruct.new
          args.determined_at = Time.now
          args.vlp_authority = 'ssa'
          consumer_role.ssn_invalid!(args)
          consumer_role.save
          return
        end

        xml_hash = xml_to_hash(xml)

        update_consumer_role(consumer_role, xml_hash)
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.ssa_responses", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

    def update_consumer_role(consumer_role, xml_hash)
      args = OpenStruct.new

      if xml_hash[:ssn_verification_failed].eql?("true")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        consumer_role.ssn_invalid!(args)
      elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("true")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        args.citizenship_result = ::ConsumerRole::US_CITIZEN_STATUS
        consumer_role.ssn_valid_citizenship_valid!(args)
      elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("false")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
        consumer_role.ssn_valid_citizenship_invalid!(args)
      end
      consumer_role.save
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end
  end
end
