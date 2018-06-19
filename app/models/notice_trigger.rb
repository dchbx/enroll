class NoticeTrigger
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :notice_template, type: String
  field :notice_builder, type: String
  field :mpi_indicator, type: String

  embedded_in :application_event_kind

  embeds_one :notice_trigger_element_group
  accepts_nested_attributes_for :notice_trigger_element_group

  after_initialize :initialize_dependent_models

  def publish(target_object, new_event)
    rule = EventForNoticeTriggerRule.new(self, new_event)
    if rule.satisfied?
      notice_builder.camelize.constantize.new(target_object, {template: notice_template, subject: application_event_kind.title, event_name: application_event_kind.event_name, mpi_indicator: mpi_indicator}.merge(notice_trigger_element_group.notice_peferences)).deliver
    else
      # log error
    end
  end

private
  def initialize_dependent_models
    build_notice_trigger_element_group if notice_trigger_element_group.nil?
  end
end
