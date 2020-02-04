# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module ContributionModels
        class ContributionUnitContract < ApplicationContract

          params do
            required(:name).filled(:string)
            required(:display_name).filled(:string)
            required(:order).filled(:integer)
          end

          rule(:member_relationship_maps).each do
            if key? && value
              result = MemberRelationshipMaps.call(value)
              key.failure(text: "invalid member relationship maps for contribution unit", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end