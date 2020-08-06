# frozen_string_literal: true

module Subscribers
  class LegacyNotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, _e_start, _e_end, _msg_id, payload)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      notice_event = event_name.split(".")[4]

      finder_mapping = ::ApplicationEventMapper.lookup_resource_mapping(event_name)
      raise ArgumentError, "BOGUS EVENT...could n't find resoure mapping for event #{event_name}." if finder_mapping.nil?
      recipient = finder_mapping.mapped_class.send(finder_mapping.search_method, payload[finder_mapping.identifier_key.to_s])
      raise ArgumentError, "Bad Payload...could n't find resoure with #{payload[finder_mapping.identifier_key.to_s]}." if recipient.blank?

      resource_hash = {:employee => "employee_role", :employer => "employer", :broker_agency => "broker_role", :consumer_role => "consumer_role", :broker => "broker_role", :general_agency => "general_agent_profile", :census_employee => "employee_role"}
      resource = ::ApplicationEventMapper.map_resource(recipient.class)
      event_kind = ::ApplicationEventKind.where(event_name: notice_event, resource_name: resource_hash[resource.resource_name]).first
      recipient = recipient.class.to_s == "EmployeeRole" ? recipient.census_employee : recipient

      if event_kind.present?
        notice_trigger = event_kind.notice_triggers.first

        builder = notice_trigger.notice_builder.camelize.constantize.new(recipient, {
          template: notice_trigger.notice_template,
          subject: event_kind.title,
          event_name: notice_event,
          options: payload['notice_params'],
          mpi_indicator: notice_trigger.mpi_indicator
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
      end
    end
  end
end
