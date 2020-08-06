# frozen_string_literal: true

module Notifier
  module Builders::Broker
    def broker_agency_account
      if event_name == 'broker_fired_confirmation_to_employer' && terminated_broker_agency_account
        terminated_broker_agency_account
      else
        employer_profile.active_broker_agency_account
      end
    end

    def terminated_broker_agency_account
      employer_profile.broker_agency_accounts.unscoped.find(payload['event_object_id']) if payload['event_object_kind'].constantize == BenefitSponsors::Accounts::BrokerAgencyAccount
    end

    def format_date(date_value)
      date_value.strftime("%m/%d/%Y") if date_value.respond_to?(:strftime)
    end

    def broker
      if broker_agency_account.present?
        broker_agency_account.writing_agent.parent
      elsif terminated_broker_agency_account.present?
        terminated_broker_agency_account.writing_agent.parent
      end
    end

    def broker_present?
      if broker.blank?
        merge_model.broker = nil
        false
      else
        true
      end
    end

    def broker_primary_fullname
      merge_model.broker.primary_fullname = broker.full_name if broker_present?
    end

    def broker_primary_first_name
      merge_model.broker.primary_first_name = broker.first_name if broker_present?
    end

    def broker_primary_last_name
      merge_model.broker.primary_last_name = broker.last_name if broker_present?
    end

    def broker_assignment_date
      merge_model.broker.assignment_date = format_date(broker_agency_account.start_on) if broker_agency_account.present?
    end

    def broker_termination_date
      merge_model.broker.termination_date = format_date(terminated_broker_agency_account.end_on) if terminated_broker_agency_account.present?
    end

    def broker_organization
      if broker_agency_account.present?
        merge_model.broker.organization = broker_agency_account.legal_name
      elsif terminated_broker_agency_account.present?
        merge_model.broker.organization = terminated_broker_agency_account.legal_name
      end
    end

    def broker_phone
      merge_model.broker.phone = broker.work_phone_or_best if broker_present?
    end

    def broker_email
      merge_model.broker.email = broker.work_email_or_best if broker_present?
    end
  end
end
