# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      #This operation will validate and create a new profile entity
      class Build
        include Dry::Monads[:result, :do]

        def call(profile_type:, profile_attrs:)
          @profile_type = yield fetch_profile_type(profile_type)
          profile_attributes = yield build_profile_params(profile_attrs)
          validated_params = yield validate(profile_attributes)
          profile_entity = yield create(validated_params)

          Success(profile_entity)
        end

        private

        def validate(params)
          profile_class = "::BenefitSponsors::Validators::Profiles::#{@profile_type}Contract".constantize
          result = profile_class.new.call(params)
          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate profile due to #{result.errors}")
          end
        end

        def create(validated_params)
          entity_class = "::BenefitSponsors::Entities::Profiles::#{@profile_type}".constantize
          profile_entity = entity_class.new(validated_params.deep_symbolize_keys!)

          Success(profile_entity)
        end

        def build_profile_params(profile_attrs)
          if @profile_type == 'AcaShopDcEmployerProfile'
            profile_attrs.merge!(is_benefit_sponsorship_eligible: true)
          else
            profile_attrs.merge!(contact_method: :paper_and_electronic)
          end
          Success(profile_attrs)
        end

        def fetch_profile_type(type)
          profile_type =
            case type
            when 'broker_agency'
              'BrokerAgencyProfile'
            when 'general_agency'
              'GeneralAgencyProfile'
            else
              'AcaShopDcEmployerProfile'
            end
          Success(profile_type)
        end
      end
    end
  end
end
