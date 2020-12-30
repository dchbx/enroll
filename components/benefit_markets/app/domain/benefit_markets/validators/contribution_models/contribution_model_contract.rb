# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module ContributionModels
      class ContributionModelContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:title).filled(:string)
          optional(:key).maybe(:symbol)
          required(:sponsor_contribution_kind).filled(:string)
          required(:contribution_calculator_kind).filled(:string)
          required(:many_simultaneous_contribution_units).filled(:bool)
          required(:product_multiplicities).array(:symbol)
          required(:contribution_units).value(:array)
          required(:member_relationships).array(:hash)
        end

        rule(:contribution_units).each do
          if key? && value
            contribution_units = [::BenefitMarkets::Entities::FixedPercentContributionUnit, ::BenefitMarkets::Entities::FixedDollarContributionUnit, ::BenefitMarkets::Entities::PercentWithCapContributionUnit]
            if !contribution_units.include?(value.class)
              if value.is_a?(Hash)
                result = ::BenefitMarkets::Validators::ContributionModels::ContributionUnitContract.new.call(value)
                key.failure(text: "invalid contribution unit", error: result.errors.to_h) if result&.failure?
              else
                key.failure(text: "invalid contribution_units. Expected a hash or contribution unit entity")
              end
            end
          end
        end

        rule(:member_relationships).each do
          if key? && value
            result = ::BenefitMarkets::Validators::ContributionModels::MemberRelationshipContract.new.call(value)
            key.failure(text: "invalid member relationshp for contribution model", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end