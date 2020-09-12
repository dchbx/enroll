# frozen_string_literal: true

module FinancialAssistance
  module Entities
    class Relationship < Dry::Struct
      transform_keys(&:to_sym)

      attribute :kind, Types::String.optional
      attribute :applicant_id, Types::Bson
      attribute :relative_id, Types::Bson

    end
  end
end