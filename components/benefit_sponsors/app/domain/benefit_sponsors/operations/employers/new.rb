# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module Employers
      #This operation will initialize a new employer profile form
      class New
        include Dry::Monads[:result, :do, :try]

        def call(params)
          validated_params = yield validate(params)
          @person = yield find_person(validated_params[:person_id]) if validated_params[:person_id].present?

          employer = yield build_employer(validated_params[:profile_type]) #get_employer_form_entity
          new_er_profile = yield new_employer(employer)
          Success(new_er_profile)
        end

        private

        def validate(params)
          if params[:profile_type].blank?
            Failure({:message => ['Missing params']})
          elsif !%w(benefit_sponsor).include?(params[:profile_type])
            Failure({:message => ['Invalid profile type']})
          else
            Success(params)
          end
        end

        def find_person(id)
          ::Operations::People::Find.new.call({person_id: id})
        end

        def build_employer(profile_type)
          Success(
            {
              profile_type: profile_type,
              staff_roles: [construct_staff_role_params],
              organization: construct_organization_params
            }
          )
        end

        def construct_staff_role_params
          staff_role_hash = {  person_id: @person&.id.to_s,
                               first_name: @person&.first_name,
                               last_name: @person&.last_name,
                               email: @person&.work_email_or_best,
                               dob: @person&.dob.strftime("%m/%d/%Y"),
                               area_code: nil,
                               number: nil
          }
          staff_role_hash.merge!(coverage_record: construct_coverage_record)
          staff_role_hash
        end

        def construct_organization_params
          organization = BenefitSponsors::Entities::Organizations::Organization.to_hash(BenefitSponsors::Organizations::GeneralOrganization.new)
          organization.merge!(profile: construct_profile_params)
        end

        def construct_profile_params
          profile = BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile.to_hash(BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new)
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

        def construct_coverage_record
          BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecord.to_hash(build_coverage_record)
        end

        def build_coverage_record
          result = CoverageRecord.new(ssn: @person&.ssn,
                                      gender: @person&.gender,
                                      dob: @person&.dob.strftime("%m/%d/%Y"),
                                      hired_on: nil,
                                      is_applying_coverage: false,
                                      address: build_address_for_coverage_record,
                                      email: build_email_for_coverage_record
          )
          result

        end

        def build_address_for_coverage_record
          home_address = @person&.home_address
          Address.new(kind: 'home',
                      address_1: home_address&.kind,
                      address_2: home_address&.address_2,
                      address_3: home_address&.address_3,
                      city: home_address&.city,
                      county: home_address&.county,
                      state: home_address&.state,
                      zip: home_address&.zip)
        end

        def build_email_for_coverage_record
          email = @person&.work_email || @person&.home_email
          Email.new(kind: email&.kind,
                    address: email&.address)
        end

        def new_employer(profile_params)
          obj = JSON.parse(profile_params.to_json, object_class: OpenStruct)
          result = set_custom_methods_on_struct(obj)
          Success(result)
        end

        def set_custom_methods_on_struct(obj)
          obj[:staff_roles_attributes] = nil
          obj.staff_roles.first[:persisted?] = false
          obj.organization.profile[:office_locations_attributes] = nil
          obj.organization.profile.office_locations.first[:persisted?] = false
          obj
        end
      end
    end
  end
end