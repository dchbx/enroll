# frozen_string_literal: true

class CurrentStatementActivity
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile_account

  field :description, type: String
  field :name, type: String
  field :type, type: String
  field :posting_date, type: Date
  field :amount, type: Money
  field :coverage_month, type: Date
  field :payment_method, type: String
  field :is_passive_renewal, type: Boolean, default: false

end
