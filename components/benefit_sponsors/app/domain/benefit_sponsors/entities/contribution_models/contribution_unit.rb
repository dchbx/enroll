# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module ContributionModels
      class ContributionUnit < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name,              Types::Strict::String
        attribute :display_name,      Types::Strict::String
        attribute :order,             Types::Strict::Integer
        attribute :member_relationship_maps, Types::Array.of(ContributionModels::MemberRelationshipMaps)

      end
    end
  end
end