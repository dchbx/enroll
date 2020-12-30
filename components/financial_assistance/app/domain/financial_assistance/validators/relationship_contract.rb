# frozen_string_literal: true

module FinancialAssistance
  module Validators
    class RelationshipContract < Dry::Validation::Contract

      params do
        required(:kind).filled(:string)
        required(:applicant_id).filled(Types::Bson)
        required(:relative_id).filled(Types::Bson)
      end
    end
  end
end
