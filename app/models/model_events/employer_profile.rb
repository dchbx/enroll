module ModelEvents
  module EmployerProfile

    REGISTERED_EVENTS = [
      :broker_hired_confirmation_to_employer,
      :welcome_notice_to_employer
    ]

    def trigger_model_event(event_name, event_options = {})
      if REGISTERED_EVENTS.include?(event_name)
        notify_observers(ModelEvent.new(event_name, self, event_options))
      end
    end

  #  def notify_on_save

  #   if !persisted?
  #     notify_observers(:on_create)
  #   else
  #     # Check changes and construct event notifications
  #     if parent.fein_changed?
  #       is_fein_change = true
  #       fein_change_options = { old_fein: parent.fein_was }
  #     end

  #     if aasm_state_changed?
  #       is_state_change = true
  #       state_change_options = { old_state: aasm_state_was }
  #     end

  #     if active_plan_year.present? && active_plan_year.start_on == TimeKeeper.date_of_record
  #       is_benefit_period_start = true
  #     end

  #     # TODO:
  #     # is_benefit_application_eligible_change  = false
  #     # old_benefit_application_eligible_change = ""

  #     # is_initial_benefit_application  = is_registered?

  #     # is_benefit_period_started           = false
  #     # old_benefit_period                  = ""

  #     # is_broker_agency_change            = false
  #     # old_broker_agency               = ""

  #     # is_general_agent_change            = false
  #     # old_general_agent               = ""

  #     # is_premium_credit                    = false
  #     # is_premium_reversed                = false

  #     # is_address_change                  = false
  #     # old_address                     = ""

  #     # is_contact_change                  = false
  #     # old_contact                     = ""

  #     # is_terminated                   = false
  #     # is_hbx_ineligible               = hbx_ineligible?

  #     # yield persists instance at this point
  #     yield
  #     # set flag that instance has changed state so Obervers are notified
  #     changed

  #     # TODO -- encapsulated notify_observers to recover from errors raised by any of the observers
  #     OBSERVER_EVENTS.each do |event|
  #       event_fired = instance_eval("is_" + event.to_s)
  #       event_name = ("on_" + event.to_s).to_sym
  #       event_options = instance_eval(event.to_s + "_options") || {}

  #       if is_defined?(event_fired) && event_fired
  #         notify_observers(event_name, self, event_options)
  #       end
  #     end
  #   end
  # end
  end
end
