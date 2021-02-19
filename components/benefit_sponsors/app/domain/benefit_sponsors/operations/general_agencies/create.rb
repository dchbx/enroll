# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module GeneralAgencies
      #This operation will create a new organization and profile
      class Create
        include Dry::Monads[:result, :do]

        def call(params)
          validated_params =    yield validate(params)
          sanitized_params =    yield sanitize_params(validated_params)
          @organization, @profile, @status = yield create_new_organization_and_profile(sanitized_params)

          _status = yield persist_organization!
          _staff_role_status, redirection_link = yield create_general_role(sanitized_params[:staff_roles], validated_params[:person_id])

          Success([redirection_link, @status])
        end

        private

        def validate(params)
          result = BenefitSponsors::Validators::Organizations::OrganizationForms::RegistrationFormContract.new.call(params)
          return Failure(text: "Invalid params", error: result.errors.to_h) if result&.failure?

          Success(params)
        end

        def sanitize_params(params)
          result = BenefitSponsors::Operations::Profiles::Sanitize.new.call(params)
          if result.success?
            result
          else
            Failure('Unable to parse Registration params')
          end
        end

        def organization_exists?(fein)
          @existing_organization = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        end

        def create_new_organization_and_profile(constructed_params)
          build_profile_result = build_profile(constructed_params[:organization][:profile])

          return Failure("Unable to build profile due to #{build_profile_result.errors.to_h}") if build_profile_result.failure?

          build_org_result = build_organization(constructed_params[:organization], build_profile_result.value!)

          return Failure("Unable to build organization due to #{build_org_result.errors.to_h}") if build_org_result.failure?
          org = create_organization(build_org_result.value!)
          profile = create_profile(org.value!, build_profile_result.value!)
          Success([org.value!, profile.value!, 'new'])
        end

        def build_profile(profile_attrs)
          result = BenefitSponsors::Operations::Profiles::Build.new.call(profile_type: 'general_agency', profile_attrs: profile_attrs)
          if result.success?
            result
          else
            Failure('Unable to build profile')
          end
        end

        def build_organization(organization_attrs, profile_entity)
          org_attrs = organization_attrs.except!(:profile).merge!(profiles: [profile_entity])
          result = BenefitSponsors::Operations::Organizations::Build.new.call(profile_type: 'general_agency', organization_attrs: org_attrs)
          if result.success?
            result
          else
            Failure('Unable to build organization')
          end
        end

        def create_organization(organization_entity)
          organization = ::BenefitSponsors::Organizations::ExemptOrganization.new(organization_entity.to_h.except(:profiles))
          Success(organization)
        end

        def create_profile(organization, profile_entity)
          profile = BenefitSponsors::Organizations::GeneralAgencyProfile.new(profile_entity.to_h)
          organization.profiles << profile
          Success(profile)
        end

        def persist_organization!
          return unless @status == 'new'

          if @organization.valid?
            Success(@organization.save!)
          else
            Failure("Unable to save organization due to #{@organization.errors.full_messages}")
          end
        end

        def create_general_role(_staff_role_params, _person_id)
          # Broker Role Vs Broker Agency Staff Role
          # if person_id.blank?
            #TODO: Create or match person
            # Success(true)
          # else
            # result = BenefitSponsors::Operations::BrokerAgencies::AddBrokerAgencyStaff.new.call(staff_role_params.merge!(profile_id: @profile.id.to_s, person_id: person_id))
            # if result.success?
            #   person = result.value![:person]
            #   redirection_link = fetch_redirection_link(person_id)
            #   Success([true, redirection_link])
            # else
            #   Failure({:message => 'Unable to create Broker role'})
            # end
          # end
          Success([true, nil])
        end

        # def fetch_redirection_link(_person_id)
        #   "broker_show_registration_url@#{@profile.id}"
        # end
      end
    end
  end
end
