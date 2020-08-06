# frozen_string_literal: true

module BenefitSponsors
  module Services
    class BrokerRegistrationService
      def self.call(params, user)
        params_validation = resolve_create_request_params_validator.call(params)
        return params_validation unless params_validation.success?
        creation_request = resolve_virtual_model.new(params_validation.output)
        process_request(creation_request, user)
      end

      # Take a Creation Request and build the underlying broker agency profile
      # and broker role items as needed.
      # @param creation_request [::BenefitSponsors::Requests::BrokerAgencyProfileCreateRequest]
      # @param user [User]
      # @return [::BenefitSponsors::Services::ServiceResponse, ::Dry::Validation::Result]
      def self.process_request(creation_request, user)
        domain_validation = resolve_create_request_domain_validator.call(user: user, request: creation_request)
        return domain_validation unless domain_validation.success?
        broker_agency_profile = find_or_create_profile_and_organization(creation_request)
        person = find_or_create_person_for_broker(creation_request, broker_agency_profile)
        ServiceResponse.new(person)
      end

      # Determines if a given user providing certain identity data
      # may claim a given broker identity.  Exposed to the domain
      # validation as a helper.
      def self.may_claim_broker_identity?(user, request)
        return false if user.person && user.person.broker_role.present?
        matched_people = get_matched_people(request.first_name, request.last_name, request.dob)
        return false if matched_people.count > 1
        broker_role_person = existing_broker_role_person(request.npn)
        if broker_role_person
          return false if broker_role_person.user_id && (broker_role_person.user_id != user.id)
          return false unless person_data_matches?(broker_role_person, request.first_name, request.last_name, request.dob)
        end
        true
      end

      private


      # The following methods provide an avenue for dependency injection.
      def resolve_create_request_params_validator
        BenefitSponsors::BrokerAgencyRegistration::CreateRequestWithAchValidators::PARAMS.new
      end

      def resolve_create_request_domain_validator
        ::BenefitSponsors::BrokerAgencyRegistration::CreateRequestValidators::DOMAIN.new
      end

      def resolve_virtual_model
        BenefitSponsors::Requests::BrokerAgencyProfileWithAchCreateRequest
      end

      def self.ensure_correct_contact_email(creation_request, matched_person)
        work_email = matched_person.emails.detect do |email|
          email.kind == "work"
        end
        if work_email.present?
          work_email.update_attributes!({
                                          address: creation_request.email
                                        })
        else
          person.emails << ::Email.new({
                                         kind: "work",
                                         address: creation_request.email
                                       })
        end
      end

      def self.find_or_create_person_for_broker(creation_request, broker_agency_profile)
        existing_person = existing_broker_role_person(creation_request.npn)
        if existing_person
          ensure_correct_contact_email(creation_request, existing_person)
          return existing_person
        end
        matched_people = get_matched_people(creation_request.first_name, creation_request.last_name, creation_request.dob)
        if matched_people.any?
          matched_person = matched_people.first
          ensure_correct_contact_email(creation_request, matched_person)
          add_broker_role_to_existing_person(matched_person, broker_agency_profile)
        else
          build_new_broker_role_and_person(creation_request, broker_agency_profile)
        end
      end

      def self.find_or_create_profile_and_organization(creation_request)
        office_locations = build_office_locations(creation_request)
        site = BenefitSponsors::ApplicationController.current_site
        profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.create!({
                                                                                  organization: ::BenefitSponsors::Organizations::ExemptOrganization.new({
                                                                                                                                                           legal_name: creation_request.legal_name,
                                                                                                                                                           dba: creation_request.dba,
                                                                                                                                                           site: site
                                                                                                                                                         }),
                                                                                  market_kind: creation_request.practice_area,
                                                                                  office_locations: office_locations,
                                                                                  accepts_new_clients: creation_request.accepts_new_clients,
                                                                                  working_hours: creation_request.evening_weekend_hours,
                                                                                  languages_spoken: creation_request.languages
                                                                                })
      end

      def self.build_office_locations(creation_request)
        primary_office_location = build_office_location(creation_request, true)
        other_office_locations = creation_request.office_locations.map do |ol|
          build_office_location(ol)
        end
        [primary_office_location] + other_office_locations
      end

      def self.build_office_location(office_location_parent, primary = false)
        BenefitSponsors::Locations::OfficeLocation.new({
                                                         is_primary: primary,
                                                         address: BenefitSponsors::Locations::Address.new({
                                                                                                            kind: (primary ? "primary" : office_location_parent.kind),
                                                                                                            address_1: office_location_parent.address.address_1,
                                                                                                            address_2: office_location_parent.address.address_2,
                                                                                                            city: office_location_parent.address.city,
                                                                                                            state: office_location_parent.address.state,
                                                                                                            zip: office_location_parent.address.zip
                                                                                                          }),
                                                         phone: BenefitSponsors::Locations::Phone.new({
                                                                                                        kind: "work",
                                                                                                        area_code: office_location_parent.phone.phone_area_code,
                                                                                                        number: office_location_parent.phone.phone_number,
                                                                                                        extension: office_location_parent.phone.phone_extension
                                                                                                      })
                                                       })
      end

      def self.add_broker_role_to_existing_person(_matched_person, broker_agency_profile)
        BrokerRole.create!(
          person: existing_person,
          npn: creation_request.npn,
          benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id
        )
      end

      def self.person_data_matches?(person, first_name, last_name, dob)
        (first_name.downcase == person.first_name.downcase) &&
          (last_name.downcase == person.last_name.downcase) &&
          (person.dob == dob)
      end

      def self.build_new_broker_role_and_person(creation_request, broker_agency_profile)
        person = Person.create({
                                 first_name: creation_request.first_name,
                                 last_name: creation_request.last_name,
                                 dob: creation_request.dob,
                                 emails: [::Email.new({
                                                        kind: "work",
                                                        address: creation_request.email
                                                      })],
                                 broker_role: BrokerRole.new({
                                                               npn: creation_request.npn,
                                                               benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id
                                                             })
                               })
        person.broker_role
      end

      def self.get_matched_people(first_name, last_name, dob)
        Person.where(
          first_name: regex_for(first_name),
          last_name: regex_for(last_name),
          dob: dob
        )
      end

      def self.existing_broker_role_person(npn)
        Person.by_broker_role_npn(npn).first
      end

      def self.regex_for(str)
        clean_string = ::Regexp.escape(str.strip)
        /^#{clean_string}$/i
      end
    end
  end
end