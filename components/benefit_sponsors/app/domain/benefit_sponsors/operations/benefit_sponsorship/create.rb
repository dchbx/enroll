# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorship
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Product Attributes
        # @return [ BenefitMarkets::Entities::Product ] product Product
        def call(params:)
          values   = yield validate(params)
          product  = yield create(values)

          Success(product)
        end

        private

        def validate(params)
          result = BenefitSponsors::Validators::BenefitSponsorships::BenefitSponsorshipContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate benefit sponsorship #{params[:_id]}")
          end
        end

        def create(values)
          benefit_sponsorship_entity = BenefitSponsors::Entities::BenefitSponsorship.new(values)

          Success(benefit_sponsorship_entity)
        end
      end
    end
  end
end