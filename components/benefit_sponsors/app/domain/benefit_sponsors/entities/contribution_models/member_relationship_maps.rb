# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module ContributionModels
      class MemberRelationshipMaps < Dry::Struct
        transform_keys(&:to_sym)

        attribute :relationship_name,     Types::Strict::Symbol
        attribute :operator,              Types::Strict::Symbol
        attribute :count,                 Types::Strict::Integer

      end
    end
  end
end