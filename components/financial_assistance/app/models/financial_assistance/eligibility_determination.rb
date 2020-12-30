# frozen_string_literal: true

module FinancialAssistance
  class EligibilityDetermination
    require 'autoinc'

    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Autoinc

    embedded_in :application, class_name: "::FinancialAssistance::Application", inverse_of: :eligibility_determinations

    field :max_aptc, type: Money, default: 0.00
    field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94
    field :source, type: String
    field :aptc_csr_annual_household_income, type: Money, default: 0.00
    field :aptc_annual_income_limit, type: Money, default: 0.00
    field :csr_annual_income_limit, type: Money, default: 0.00
    field :effective_starting_on, type: Date
    field :effective_ending_on, type: Date
    field :is_eligibility_determined, type: Boolean
    field :hbx_assigned_id, type: Integer
    increments :hbx_assigned_id, seed: 9999

    field :determined_at, type: Date


    scope :eligibility_determination_with_year, ->(year) { where(effective_starting_on: (Date.new(year)..Date.new(year).end_of_year), is_eligibility_determined: true) }
    scope :active_eligibility_determination, ->{ where(effective_ending_on: nil, is_eligibility_determined: true) }

    def applicants
      application.applicants.in(eligibility_determination_id: id)
    end
  end
end

