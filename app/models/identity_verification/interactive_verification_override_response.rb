# frozen_string_literal: true

module IdentityVerification
  class InteractiveVerificationOverrideResponse
    include HappyMapper

    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'
    tag 'interactive_verification_override_result'
    namespace 'acapi'

    element 'response_code', String
    element 'response_text', String
    element 'transaction_id', String

    def successful?
      return false if response_code.blank?
      response_code.strip == "urn:openhbx:terms:v1:interactive_identity_verification#SUCCESS"
    end

  end
end
