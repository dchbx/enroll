# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ContributionUnits
      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ contribution_unit_params ] params Contribution Unit attributes
        # @param [ sponsor_contribution_kind ] Type of sponsor contribution - fixed percent, fixed dollar, percent with cap
        # @return [ BenefitMarkets::Entities::ContributionUnit ] contribution_unit entity
        def call(contribution_unit_params:, sponsor_contribution_kind:)
          contribution_unit_type        = yield fetch_contribution_unit_kind(sponsor_contribution_kind)
          validated_params              = yield validate(contribution_unit_params, contribution_unit_type)
          contribution_unit             = yield create(validated_params, contribution_unit_type)

          Success(contribution_unit)
        end

        private

        def validate(params, type)
          contribution_unit_class = "::BenefitMarkets::Validators::ContributionModels::#{type}Contract".constantize
          result = contribution_unit_class.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate contribution unit due to #{result.errors}")
          end
        end

        def fetch_contribution_unit_kind(kind)
          sponsor_contribution_kind = kind.demodulize
          contribution_unit_type =
            case sponsor_contribution_kind
            when 'FixedPercentSponsorContribution'
              'FixedPercentContributionUnit'
            when 'FixedPercentWithCapSponsorContribution'
              'PercentWithCapContributionUnit'
            else
              'ContributionUnit'
            end
          Success(contribution_unit_type)
        end

        def create(values, type)
          entity_class = "::BenefitMarkets::Entities::#{type}".constantize
          contribution_unit = entity_class.new(values)

          Success(contribution_unit)
        end
      end
    end
  end
end