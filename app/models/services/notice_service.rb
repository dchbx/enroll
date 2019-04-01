module Services
  class NoticeService
    include Acapi::Notifiers

    def deliver(recipient:, event_object:, notice_event:, notice_params: {})
      return if recipient.blank? || event_object.blank?
      begin
        resource = Notifier::ApplicationEventMapper.map_resource(recipient.class)
        event_name = Notifier::ApplicationEventMapper.map_event_name(resource, notice_event)
        notify(event_name, {
          resource.identifier_key => recipient.send(resource.identifier_method).to_s,
          :event_object_kind => event_object.class.to_s,
          :event_object_id   => event_object.id.to_s,
          :notice_params => notice_params
          })
      rescue Exception => e
        Rails.logger.error { "Could not deliver #{notice_event} notice due to #{e}" }
        raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
      end
    end
  end
end
