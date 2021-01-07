# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Organizations
      #This operation will validate and create a new organization entity
      class Build
        include Dry::Monads[:result, :do]

        def call(profile_type:, organization_attrs:)
          @organization_type = yield fetch_organization_type(profile_type)
          profile_attributes = yield build_organization_params(organization_attrs)
          validated_params = yield validate(profile_attributes)
          organization_entity = yield create(validated_params)

          Success(organization_entity)
        end

        private

        def validate(params)
          profile_class = "::BenefitSponsors::Validators::Organizations::#{@organization_type}Contract".constantize
          result = profile_class.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate profile due to #{result.errors}")
          end
        end

        def create(validated_params)
          entity_class = "::BenefitSponsors::Entities::Organizations::#{@organization_type}".constantize
          organization_entity = entity_class.new(validated_params)

          Success(organization_entity)
        end

        def build_organization_params(organization_attrs)
          Success(organization_attrs.merge!(site_id: fetch_site_id))
        end

        def fetch_site_id
          BenefitSponsors::ApplicationController.current_site.id
        end

        def fetch_organization_type(type)
          org_type =
            case type
            when 'benefit_sponsor', 'general_agency'
              'GeneralOrganization'
            else
              'ExemptOrganization'
            end
          Success(org_type)
        end
      end
    end
  end
end
