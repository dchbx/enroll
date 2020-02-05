# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module BenefitPackages
      class BenefitPackage < Dry::Struct
        transform_keys(&:to_sym)

        attribute :title, Types::Strict::String
        attribute :description, Types::Strict::String
        attribute :probation_period_kind, Types::Strict::Symbol
        attribute :is_default, Types::Strict::Bool
        attribute :is_active, Types::Strict::Bool
        attribute :predecessor_id, Types::Strict::String

        attribute :sponsored_benefits, Entities::SponsoredBenefits::SponsoredBenefit

      end
    end
  end
end