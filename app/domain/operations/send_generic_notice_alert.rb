# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SendGenericNoticeAlert
    send(:include, Dry::Monads[:result, :do, :try])

    include Config::SiteHelper

    def call(resource:)
      return Failure({:message => ['Please find valid resource to send the alert message']}) if resource.blank?

      @resource = resource
      recipient_target = yield fetch_recipient_target

      return Success(true) if recipient_target.blank?

      recipient_name = yield fetch_recipient_name(recipient_target)
      recipient_email = yield fetch_recipient_email(recipient_target)

      send_notice_alert_to_resource(recipient_name, recipient_email)
      send_notice_alert_to_broker_and_ga

      Success(true)
    end

    private


    def fetch_recipient_target
      if is_employer?
        Success(@resource.staff_roles.first)
      elsif is_general_agency?
        Success(@resource.general_agency_primary_staff&.person)
      elsif is_person?
        Success(@resource)
      end
    end

    def fetch_recipient_name(recipient_target)
      Success(recipient_target.full_name.titleize)
    end

    def fetch_recipient_email(recipient_target)
      Success(recipient_target.work_email_or_best)
    end

    def send_notice_alert_to_resource(name, target)
      UserMailer.generic_notice_alert(name, "You have a new message from #{site_short_name}", target).deliver_now  unless is_valid_resource? && !can_receive_electronic_communication?
      Success(true)
    end

    def send_notice_alert_to_broker_and_ga
      if is_employer?
        if @resource.broker_agency_profile.present?
          broker_person = @resource.broker_agency_profile.primary_broker_role.person
          broker_name = broker_person.full_name
          broker_email = broker_person.work_email_or_best
          UserMailer.generic_notice_alert_to_ba_and_ga(broker_name, broker_email, @resource.legal_name.titleize).deliver_now
        end
        if @resource.general_agency_profile.present?
          general_agency_staff_person = @resource.general_agency_profile.primary_staff.person
          general_agent_name = general_agency_staff_person.full_name
          ga_email = general_agency_staff_person.work_email_or_best
          UserMailer.generic_notice_alert_to_ba_and_ga(general_agent_name, ga_email, @resource.legal_name.titleize).deliver_now
        end
      end
      Success(true)
    end

    def is_valid_resource?
      is_employer? || is_person? || is_general_agency?
    end

    def is_person?
      @resource.is_a?(Person)
    end

    def is_employer?
      @resource.is_a?("BenefitSponsors::Organizations::AcaShop#{site_key.capitalize}EmployerProfile".constantize) || @resource.is_a?(BenefitSponsors::Organizations::FehbEmployerProfile)
    end

    def is_general_agency?
      @resource.is_a?(BenefitSponsors::Organizations::GeneralAgencyProfile)
    end

    # TODO: Confirm on what basis we need to send electronic communication to general agency staff
    def can_receive_electronic_communication?
      if is_employer?
        @resource.can_receive_electronic_communication?
      elsif is_person?
        @resource.consumer_role.present? && @resource.consumer_role.can_receive_electronic_communication? ||
          @resource.employee_roles.present? && @resource.employee_roles.any?(&:can_receive_electronic_communication?)
      elsif is_general_agency?
        true
      end
    end

  end
end
