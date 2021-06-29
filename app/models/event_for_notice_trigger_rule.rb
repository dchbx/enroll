# frozen_string_literal: true

class EventForNoticeTriggerRule

  def initialize(notice_trigger, application_event)
    @application_event = application_event
    @notice_trigger = notice_trigger
  end

  def satisfied?
    @errors = []
    true
  end

  # delivery method available?
  def is_primary_recipient_notice_satisfied?
    delivery_method = @notice.notice_trigger_element_group.primary_recipient_delivery_method
    true if delivery_method == "any"
  end

  def noticable_event; end

  # electronic delivery method available?
  def is_secondary_recipient_notice_satisfied?; end

  def determination_results
    @errors
  end

  def work_email; end

  def home_email; end

  def mailing_address; end

  def primary_address; end
end
