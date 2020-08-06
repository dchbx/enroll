# frozen_string_literal: true

module IdentityVerification
  class InteractiveQuestionResponseOption
    include HappyMapper

    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'
    tag 'response_option'
    namespace 'acapi'

    element :response_id, String
    element :response_text, String
  end
end
