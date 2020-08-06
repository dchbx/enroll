# frozen_string_literal: true

module IdentityVerification
  class InteractiveQuestion
    include HappyMapper

    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'
    tag 'question'
    namespace 'acapi'

    element :question_id, String
    element :question_text, String

    has_many :response_options, "IdentityVerification::InteractiveQuestionResponseOption", :tag => "response_option"
  end
end
