# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module Profiles
      class Registration
        include Dry::Monads[:result, :do]


        def call(params)
          parsed_params = yield parse_params(params)
          profile_entity =  yield build_profile(parsed_params[:profile_type], parsed_params[:organization][:profile])
          organization_entity = yield build_organization(parsed_params[:profile_type], parsed_params[:organization], profile_entity)
          organization = yield create_organization(parsed_params[:profile_type], organization_entity)
          _profile = yield create_profile(parsed_params[:profile_type], organization, profile_entity)
          yield persist_organization!(organization)

          Success(organization)
        end

        private

        def parse_params(params)
          result = BenefitSponsors::Operations::Profiles::Parse.new.call(params)
          if result.success?
            result
          else
            Failure('Unable to parse Registration params')
          end
        end

        def build_profile(type, profile_attrs)
          result = BenefitSponsors::Operations::Profiles::Build.new.call(profile_type: type, profile_attrs: profile_attrs)
          if result.success?
            result
          else
            Failure('Unable to build profile')
          end
        end

        def build_organization(type, organization_attrs, profile_entity)
          org_attrs = organization_attrs.except!(:profile).merge!(profiles: [profile_entity])
          result = BenefitSponsors::Operations::Organizations::Build.new.call(profile_type: type, organization_attrs: org_attrs)
          if result.success?
            result
          else
            Failure('Unable to build organization')
          end
        end

        def create_organization(type, organization_entity)
          profile_type = fetch_org_type(type)
          organization =  "::BenefitSponsors::Organizations::#{profile_type}".constantize.new(organization_entity.to_h.except(:profiles))
          Success(organization)
        end

        def create_profile(type, organization, profile_entity)
          profile_type = fetch_profile_type(type)
          profile =  "::BenefitSponsors::Organizations::#{profile_type}".constantize.new(profile_entity.to_h)
          organization.profiles << profile
          profile.add_benefit_sponsorship if profile_type == 'AcaShopDcEmployerProfile'
          Success(organization)
        end

        def persist_organization!(organization)
          if organization.valid?
            organization.benefit_sponsorships.each do |benefit_sponsorship|
              benefit_sponsorship.save! if benefit_sponsorship.new_record?
            end
            Success(organization.save!)
          else
            Failure("Unable to save organization due to #{organization.errors.full_messages}")
          end
        end

        def fetch_org_type(type)
         org_type =  case type
                     when 'benefit_sponsor', 'general_agency'
                       'GeneralOrganization'
                     else
                       'ExemptOrganization'
                     end
          org_type
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
          profile_type
        end
      end
    end
  end
end
