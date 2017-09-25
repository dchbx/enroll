module Subscribers
  class FinancialAssistanceApplicationOutstandingVerification < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      # ["acapi.info.events.lawful_presence.ssa_verification_response"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      haven_verifications_import_from_xml(payload)
    end

    def haven_verifications_import_from_xml(xml)
      verified_f = Parsers::Xml::Cv::OutstandingVerificationParser.new
      v = verified_f.parse(xml)
    end
  end
end