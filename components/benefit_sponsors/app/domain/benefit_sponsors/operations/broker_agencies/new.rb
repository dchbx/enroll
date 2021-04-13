# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module BrokerAgencies
      #This operation will initialize a new employer profile form
      class New
        include Dry::Monads[:result, :do, :try]

        def call(params)
          validated_params = yield validate(params)
          @person = yield find_person(validated_params[:person_id]) if validated_params[:person_id].present?

          employer = yield build_broker(validated_params[:profile_type])
          Success(employer)
        end

        private

        def validate(params)
          if params[:profile_type].blank?
            Failure({:message => ['Missing profile type']})
          elsif !%w[broker_agency].include?(params[:profile_type])
            Failure({:message => ['Invalid profile type']})
          else
            Success(params)
          end
        end

        def find_person(id)
          ::Operations::People::Find.new.call({person_id: id})
        end

        def build_broker(profile_type)
          params_hash = { profile_type: profile_type,
                          staff_roles: [construct_staff_role_params],
                          organization: construct_organization_params }

          obj = JSON.parse(params_hash.to_json, object_class: OpenStruct)
          result = add_custom_methods_on_struct(obj)
          Success(result)
        end

        def construct_staff_role_params
          { person_id: @person&.id.to_s,
            first_name: @person&.first_name,
            last_name: @person&.last_name,
            email: @person&.work_email_or_best,
            dob: @person&.dob&.strftime("%m/%d/%Y"),
            area_code: nil,
            number: nil }
        end

        def construct_organization_params
          organization = BenefitSponsors::Entities::Organizations::Organization.to_hash(BenefitSponsors::Organizations::ExemptOrganization.new)
          organization.merge!(profile: construct_profile_params)
        end

        def construct_profile_params
          profile = BenefitSponsors::Entities::Profiles::BrokerAgencyProfile.to_hash(BenefitSponsors::Organizations::BrokerAgencyProfile.new)
          profile.merge!(office_locations: [construct_office_location])
        end

        def construct_office_location
          BenefitSponsors::Entities::OfficeLocations::OfficeLocation.to_hash(BenefitSponsors::Locations::OfficeLocation.new(address: construct_address, phone: construct_phone))
        end

        def construct_address
          BenefitSponsors::Locations::Address.new
        end

        def construct_phone
          BenefitSponsors::Locations::Phone.new
        end

        def add_custom_methods_on_struct(obj)
          obj[:staff_roles_attributes] = nil
          obj[:persisted?] = false
          obj.staff_roles.first[:persisted?] = false
          obj.organization.profile[:office_locations_attributes] = nil
          obj.organization.profile.office_locations.first[:persisted?] = false
          obj.organization.profile.office_locations.each do |ol|
            ol.address.office_kind_options = BenefitSponsors::Locations::Address::OFFICE_KINDS
          end
          obj
        end
      end
    end
  end
end
