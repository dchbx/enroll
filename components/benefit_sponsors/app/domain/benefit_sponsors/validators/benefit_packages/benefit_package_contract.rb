# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module BenefitPackages
      class BenefitPackageContract < Dry::Validation::Contract

        params do
          required(:title).filled(:string)
          required(:description).filled(:string)
          required(:probation_period_kind).filled(:symbol)
          required(:is_default).filled(:bool)
          required(:is_active).filled(:bool)
          optional(:predecessor_id).maybe(Types::Bson)
          optional(:sponsored_benefits).array(:hash)
        end

        rule(:sponsored_benefits) do
          if key? && value
            sponsored_benefits_array = value.inject([]) do |hash_array, sb_hash|
              if sb_hash.is_a?(Hash)
                result = BenefitSponsors::Validators::SponsoredBenefits::SponsoredBenefitContract.new.call(sb_hash)
                if result&.failure?
                  key.failure(text: 'invalid sponsored_benefit', error: result.errors.to_h)
                else
                  hash_array << result.to_h
                end
              else
                key.failure(text: 'invalid sponsored_benefit. Expected a hash.')
              end
              hash_array
            end
            values.merge!(sponsored_benefits: sponsored_benefits_array)
          end
        end
      end
    end
  end
end
