# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplications
      # This class initializes a benefit_application entity after
      # validating the incoming benefit_application params.
      class Build
        include Dry::Monads[:result, :do]

        # @param [ Hash ] benefit_application attributes
        # @return [ BenefitSponsors::Entities::BenefitApplication ] benefit_application
        def call(params)
          values = yield validate(params)
          entity = yield initialize_entity(values)

          Success(entity)
        end

        private

        def validate(params)
          contract_result = ::BenefitSponsors::Validators::BenefitApplications::BenefitApplicationContract.new.call(params)
          contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
        end

        def initialize_entity(values)
          ba_params = values.to_h
          ba_params[:benefit_packages].each do |bp_params|
            sb_entities = bp_params[:sponsored_benefits].inject([]) do |sbs_array, sb_params|
              sbs_array << init_sponored_benefit(sb_params)
            end
            bp_params[:sponsored_benefits] = sb_entities
          end

          Success(::BenefitSponsors::Entities::BenefitApplication.new(ba_params))
        end

        def init_sponored_benefit(sb_params)
          entity_class = if sb_params[:product_kind].present?
                           "::BenefitSponsors::Entities::#{sb_params[:product_kind].to_s.camelize}SponsoredBenefit".constantize
                         else
                           ::BenefitSponsors::Entities::SponsoredBenefit
                         end
          entity_class.new(sb_params)
        end
      end
    end
  end
end
