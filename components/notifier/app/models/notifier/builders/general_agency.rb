module Notifier
  class Builders::GeneralAgency
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::Broker
    include Notifier::ApplicationHelper

    attr_accessor :general_agency, :merge_model, :payload

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

    def broker
      return @broker if defined? @broker
      if payload[:event_object_kind].constantize == BrokerAgencyProfile
        @broker = BrokerAgencyProfile.find(payload[:event_object_id])
      end
    end

    def broker_primary_fullname
      return if broker.blank?
      merge_model.broker.primary_fullname = broker.primary_broker_role.person.full_name.titleize
    end

    def broker_organization
      return if broker.blank?
      merge_model.broker.organization = broker.legal_name.titleize
    end

    def assignment_date
      merge_model.assignment_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end
  end
end