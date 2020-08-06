# frozen_string_literal: true

module Subscribers
  class SsaVerification < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.lawful_presence.ssa_verification_response"]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      process_response(payload)
    end

    private

    def process_response(payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload['body']
      person_hbx_id = stringed_key_payload['individual_id']
      return_status = stringed_key_payload["return_status"].to_s

      person = find_person(person_hbx_id)
      return if person.nil? || person.consumer_role.nil?

      consumer_role = person.consumer_role
      event_response_record = EventResponse.new({received_at: Time.now, body: xml})
      consumer_role.lawful_presence_determination.ssa_responses << event_response_record
      person.verification_types.active.reject{|type| ["DC Residency", "American Indian Status", "Immigration status"].include? type.type_name}.each do |type|
        type.add_type_history_element(action: "SSA Hub Response",
                                      modifier: "external Hub",
                                      update_reason: "Hub response",
                                      event_response_record_id: event_response_record.id)
      end

      #TODO: change response handler
      if return_status.to_s == "503"
        args = OpenStruct.new
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        consumer_role.ssn_invalid!(args)
        consumer_role.save
        return
      end

      xml_hash = xml_to_hash(xml)

      update_consumer_role(consumer_role, xml_hash)
    rescue StandardError => e
      notify("acapi.error.application.enroll.remote_listener.ssa_responses", {
               :body => JSON.dump({
                                    :error => e.inspect,
                                    :message => e.message,
                                    :backtrace => e.backtrace
                                  })
             })
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
      Person.where(hbx_id: person_hbx_id).first
    end
  end
end
