class ShopNoticesNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(id, event, options = {})
    Resque.logger.level = Logger::DEBUG
    profile = EmployerProfile.find(id) || GeneralAgencyProfile.find(id) || CensusEmployee.where(id: id).first
    event_kind = ApplicationEventKind.where(:event_name => event).first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(profile, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              event_name: event,
              options: options,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
  end
end
