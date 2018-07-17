class IvlNoticesNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(person_id, event, options={})
    Resque.logger.level = Logger::DEBUG
    person = Person.find(person_id)
    role = person.consumer_role || person.resident_role
    event_kind = ApplicationEventKind.where(:event_name => event).first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(role, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              event_name: event,
              options: options,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver

  end
end