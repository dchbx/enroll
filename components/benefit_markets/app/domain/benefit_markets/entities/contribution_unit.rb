# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class ContributionUnit < Dry::Struct
      transform_keys(&:to_sym)

      attribute :_id,                       Types::Bson
      attribute :name,                      Types::Strict::String
      attribute :display_name,              Types::Strict::String
      attribute :order,                     Types::Strict::Integer
      attribute :member_relationship_maps,  Types::Array.of(BenefitMarkets::Entities::MemberRelationshipMap)

    end
  end
end