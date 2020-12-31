module Subscribers
  class LegacyNotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      notice_event = event_name.split(".")[4]

      finder_mapping = ::ApplicationEventMapper.lookup_resource_mapping(event_name)
      if finder_mapping.nil?
        raise ArgumentError.new("BOGUS EVENT...could n't find resoure mapping for event #{event_name}.")
      end
      recipient = finder_mapping.mapped_class.send(finder_mapping.search_method, payload[finder_mapping.identifier_key.to_s])
      if recipient.blank?
        raise ArgumentError.new("Bad Payload...could n't find resoure with #{payload[finder_mapping.identifier_key.to_s]}.")
      end

      resource_hash = {:employee => "employee_role", :employer => "employer", :broker_agency => "broker_role", :consumer_role => "consumer_role", :broker => "broker_role", :general_agency => "general_agent_profile", :census_employee => "employee_role"}
      resource   = ::ApplicationEventMapper.map_resource(recipient.class)
      event_kind = ::ApplicationEventKind.where(event_name: notice_event, resource_name: resource_hash[resource.resource_name]).first
      recipient = recipient.class.to_s == "EmployeeRole" ? recipient.census_employee : recipient

      if event_kind.present?
        notice_trigger = event_kind.notice_triggers.first

        notice_class(notice_trigger.notice_builder).new(recipient, {
          template: notice_trigger.notice_template,
          subject: event_kind.title,
          event_name: notice_event,
          options: payload['notice_params'],
          mpi_indicator: notice_trigger.mpi_indicator
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
      end
    end

    def notice_class(notice_type)
      notice_class = ['IvlNotice',
                      'Notice',
                      'IvlNotices::ConditionalEligibilityNoticeBuilder',
                      'IvlNotices::CoverallToIvlTransitionNoticeBuilder',
                      'IvlNotices::DocumentsVerification',
                      'IvlNotices::EligibilityDenialNoticeBuilder',
                      'IvlNotices::EligibilityNoticeBuilder',
                      'IvlNotices::EnrollmentNoticeBuilder',
                      'IvlNotices::EnrollmentNoticeBuilderWithDateRange',
                      'IvlNotices::FinalCatastrophicPlanNotice',
                      'IvlNotices::IneligibilityNoticeBuilder',
                      'IvlNotices::IvlBacklogVerificationNoticeUqhp',
                      'IvlNotices::IvlRenewalNotice',
                      'IvlNotices::IvlTaxNotice',
                      'IvlNotices::IvlToCoverallTransitionNoticeBuilder',
                      'IvlNotices::IvlVtaNotice',
                      'IvlNotices::NoAppealVariableIvlRenewalNotice',
                      'IvlNotices::NoticeBuilder',
                      'IvlNotices::ReminderNotice',
                      'RenewalNotice',
                      'IvlNotices::SecondIvlRenewalNotice',
                      'IvlNotices::VariableIvlRenewalNotice'].find { |x| x == notice_type.classify }
      raise "Unable to find the notice_class" if notice_class.nil?
      notice_class.camelize.constantize
    end
  end
end
