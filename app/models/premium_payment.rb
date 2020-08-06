# frozen_string_literal: true

class PremiumPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile_account

  MethodKinds = %w[ach credit_card check].freeze

  # Payment status
  field :paid_on, type: Date
  field :amount, type: Money

  # Payment instrument
  field :method_kind, type: String

  # For Payment by check

  # Confirmation ID or similar
  field :reference_id, type: String

  # Network reference to the payment document
  field :document_uri, type: String

  validates_presence_of :paid_on, :amount, :method_kind, :reference_id

end
