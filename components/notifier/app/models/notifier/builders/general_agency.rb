module Notifier
  class Builders::GeneralAgency
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::Broker
    include Notifier::ApplicationHelper

    attr_accessor :general_agency, :merge_model, :payload, :event_name

    def initialize
      data_object = Notifier::MergeDataModels::GeneralAgency.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      @merge_model = data_object
    end

    def resource=(resource)
      @general_agency = resource
    end

    def append_contact_details
      if general_agency.primary_staff.present?
        merge_model.first_name = general_agency.primary_staff.person.first_name
        merge_model.last_name = general_agency.primary_staff.person.last_name
      end

      office_address = general_agency.organization.primary_office_location.address
      if office_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: office_address.address_1,
          street_2: office_address.address_2,
          city: office_address.city,
          state: office_address.state,
          zip: office_address.zip
          })
      end
    end

    def email
      merge_model.email = agency_staff.work_email_or_best
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def legal_name
      merge_model.legal_name = general_agency.legal_name
    end

    def agency_staff
      general_agency.primary_staff.person if general_agency.primary_staff.present?
    end

    def first_name
      if agency_staff.present?
        merge_model.first_name = agency_staff.first_name
      end
    end

    def last_name
      if agency_staff.present?
        merge_model.last_name = agency_staff.last_name
      end
    end

    def employer
      return @employer if defined? @employer

      return unless payload['event_object_kind'].constantize == BenefitSponsors::Organizations::AcaShopDcEmployerProfile

      @employer = BenefitSponsors::Organizations::Profile.find payload['event_object_id']
    end

    def employer_name
      merge_model.employer_name = employer.legal_name
    end

    def employer_staff_role
      employer.staff_roles.first
    end

    def employer_poc_firstname
      merge_model.employer_poc_firstname = employer_staff_role.first_name
    end

    def employer_poc_lastname
      merge_model.employer_poc_lastname = employer_staff_role.last_name
    end

    def general_agency_account
      return @general_agency_account if defined? @general_agency_account

      return unless payload['notice_params'].present? && payload['notice_params']['general_agency_account_id'].present?

      employer.general_agency_accounts.find(payload['notice_params']['general_agency_account_id'])
    end

    def broker_role
      return @broker if defined? @broker

      if general_agency_account
        @broker = BrokerRole.find(general_agency_account.broker_role_id)
      elsif payload['event_object_kind'].constantize == BrokerAgencyProfile
        @broker = BenefitSponsors::Organizations::BrokerAgencyProfile.find(payload['event_object_id']).primary_broker_role
      elsif payload['notice_params'] && payload['notice_params']['broker_agency_profile_id']
        @broker = BenefitSponsors::Organizations::BrokerAgencyProfile.find(payload['notice_params']['broker_agency_profile_id']).primary_broker_role
      end
    end

    def broker_primary_fullname
      return if broker.blank?

      merge_model.broker.primary_fullname = broker_role.primary_broker_role.person.full_name.titleize
    end

    def broker_primary_first_name
      return if broker_role.blank?

      merge_model.broker.primary_first_name = broker_role.person.first_name.titleize
    end

    def broker_primary_last_name
      return if broker_role.blank?

      merge_model.broker.primary_last_name = broker_role.person.last_name.titleize
    end

    def broker_organization
      return if broker.blank?

      merge_model.broker.organization = broker_role.legal_name.titleize
    end

    def assignment_date
      merge_model.assignment_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def termination_date
      merge_model.termination_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end
  end
end