# frozen_string_literal: true

module Forms
  class BrokerAgencyProfileForm

    BROKER = "broker"

    def initialize(params, current_user)
      @params = params
      @current_user = current_user
    end

    def self.model_name
      ::BrokerAgencyProfile.model_name
    end

    def build_and_assign_attributes
      build_organization
      assign_organization_params
      # save_and_match_broker
    end

    def bubble_broker_agency_profile_errors
      bap = @organization.broker_agency_profile
      @organization.errors.delete(:broker_agency_profile)
      bap.errors.each do |attr, err|
        @organization.errors.add("broker_agency_profile_attributes_#{attr}", err)
      end
    end

    def save
      (@organization.save && @current_user.save).tap do
        bubble_broker_agency_profile_errors
      end
    end

    def check_broker_match(npn)
      BrokerRole.find_by_npn(npn)
    end

    def save_and_match_broker
      @person_1 = broker_agency_profile.broker_agency_contacts.first
      @broker_role = person_1.broker_role
      @person_1.save!
      check_broker_match(broker_role.npn)
    end

    def assign_organization_params
      @organization.attributes = @params["organization"]
      broker_agency_profile = @organization.broker_agency_profile
#      broker_role = broker_agency_profile.broker_agency_contacts.first.broker_role
#      broker_agency_profile.primary_broker_role = broker_role
      @person = @current_user.person.present? ? @current_user.person : @current_user.build_person(first_name: @params[:first_name], last_name: @params[:last_name])
#      @person.broker_agency_contact = broker_agency_profile
#      broker_role.broker_agency_profile = broker_agency_profile
      @current_user.roles << BROKER unless @current_user.roles.include?(BROKER)
      [@organization, @current_user]
    end

    def build_broker_agency_profile_params
      build_organization
      build_office_location
      build_broker_agency
      @organization
    end

    def build_organization
      @organization = Organization.new
      @broker_agency_profile = @organization.build_broker_agency_profile
    end

    def build_office_location
      @organization.office_locations.build unless @organization.office_locations.present?
      office_location = @organization.office_locations.first
      office_location.build_address unless office_location.address.present?
      office_location.build_phone unless office_location.phone.present?
    end

    def build_broker_agency
#      @broker_agency_profile.broker_agency_contacts.build unless @broker_agency_profile.broker_agency_contacts.present?
#      broker_agency_contact = @broker_agency_profile.broker_agency_contacts.first
#      broker_agency_contact.emails.build unless broker_agency_contact.emails.present?
#      broker_agency_contact.build_broker_role unless broker_agency_contact.broker_role.present?
    end

  end
end
