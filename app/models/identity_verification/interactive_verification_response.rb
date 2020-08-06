# frozen_string_literal: true

module IdentityVerification
  class InteractiveVerificationResponse
    include HappyMapper
    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'

    tag 'interactive_verification_result'
    namespace 'acapi'

    element 'verification_result', "IdentityVerification::InteractiveVerificationResult"

    element "session", "IdentityVerification::InteractiveVerificationSession"

    def successful?
      return false if verification_result.nil?
      response_code == "urn:openhbx:terms:v1:interactive_identity_verification#SUCCESS"
    end

    def failed?
      response_code == "urn:openhbx:terms:v1:interactive_identity_verification#FAILURE"
    end

    def response_code
      either_child_property(:response_code)
    end

    def response_text
      return nil if verification_result.nil?
      verification_result.response_text
    end

    def transaction_id
      either_child_property(:transaction_id)
    end

    def either_child_property(prop, default_prop_val = nil)
      return(session.send(prop)) unless session.nil?
      return(verification_result.send(prop)) unless verification_result.nil?
      default_prop_val
    end

    def questions
      return [] if session.nil?
      session.questions
    end

    def session_id
      return nil if session.nil?
      session.session_id
    end

    def continue_session?
      !session.nil?
    end

    def to_model
      question_attributes = {}
      questions.each_with_index do |q, idx|
        response_attributes = {}
        q.response_options.each_with_index do |ro, r_idx|
          response_attributes[r_idx] = {
            response_id: ro.response_id,
            response_text: ro.response_text
          }
        end
        question_attributes[idx.to_s] = {
          question_id: q.question_id,
          question_text: q.question_text,
          responses_attributes: response_attributes
        }
      end
      ::IdentityVerification::InteractiveVerification.new(
        :session_id => session_id,
        :transaction_id => transaction_id,
        :questions_attributes => question_attributes
      )
    end
  end
end
