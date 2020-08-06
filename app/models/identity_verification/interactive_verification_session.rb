# frozen_string_literal: true

module IdentityVerification
  class InteractiveVerificationSession
    include HappyMapper

    register_namespace 'acapi', 'http://openhbx.org/api/terms/1.0'
    tag 'session'
    namespace 'acapi'

    element 'response_code', String
    element 'transaction_id', String
    element 'session_id', String

    has_many :questions, "IdentityVerification::InteractiveQuestion", :tag => "question"
  end
end
