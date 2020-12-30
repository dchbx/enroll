# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module ContributionModels
      class ContributionUnitContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:name).filled(:string)
          required(:display_name).filled(:string)
          required(:order).filled(:integer)
          required(:member_relationship_maps).array(:hash)
        end

        rule(:member_relationship_maps).each do
          if key? && value
            result = MemberRelationshipMapContract.new.call(value)
            key.failure(text: "invalid member relationship maps for contribution unit", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end