class ShopNoticesNotifierJob < ActiveJob::Base
  include Acapi::Notifiers
  queue_as :default

  def perform(id, event, options = {})
    recipient = EmployerProfile.find(id) || GeneralAgencyProfile.find(id) || CensusEmployee.where(id: id).first
    if  options['acapi_trigger'].present? && options['acapi_trigger']
      begin
        resource = ApplicationEventMapper.map_resource(recipient.class)
        event_name = ApplicationEventMapper.map_event_name(resource, event)
        notify(event_name, {
          resource.identifier_key => recipient.send(resource.identifier_method).to_s,
          :event_object_kind => recipient.class.to_s, #no event object in legacy way of trigger notices
          :event_object_id   => recipient.id.to_s, #passing in recipient as of now
          :notice_params => options
          })
      rescue Exception => e
        Rails.logger.error { "Could not deliver #{event} notice due to #{e}" }
        raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
      end
    else
      Resque.logger.level = Logger::DEBUG
      event_kind = ApplicationEventKind.where(:event_name => event).first
      notice_trigger = event_kind.notice_triggers.first
      builder = notice_trigger.notice_builder.camelize.constantize.new(recipient, {
                template: notice_trigger.notice_template,
                subject: event_kind.title,
                event_name: event,
                options: options,
                mpi_indicator: notice_trigger.mpi_indicator,
                }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
    end
  end
end