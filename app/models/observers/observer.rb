module Observers
  class Observer
    include Acapi::Notifiers

    def trigger_notice(recipient:, event_object:, notice_event:)
      return if recipient.blank? || event_object.blank?
      resource_mapping = Notifier::ApplicationEventMapper.map_resource(recipient.class)
      event_name = Notifier::ApplicationEventMapper.map_event_name(resource_mapping, notice_event)
      log("OBSERVER NOTICE EVENT: #{event_name}, event_object_kind: #{event_object.class.to_s}, event_object_id: #{event_object.id.to_s}", {:severity => 'info'})
      notify(event_name, {
        resource_mapping.identifier_key => recipient.send(resource_mapping.identifier_method).to_s,
        :event_object_kind => event_object.class.to_s,
        :event_object_id => event_object.id.to_s
      })
    end

    def organizations_for_force_publish(new_date)
      Organization.where({:'employer_profile.plan_years' =>
                                 {:$elemMatch => {
                                     :start_on => new_date.next_month.beginning_of_month,
                                     :aasm_state => 'renewing_draft'
                                 }}
                         })
    end

    def organizations_for_open_enrollment_end(new_date)
      Organization.where(:"employer_profile.plan_years" =>
                             {:$elemMatch => {
                                 :"open_enrollment_end_on".lt => new_date,
                                 :"start_on".gt => new_date,
                                 :"aasm_state".in => ['published', 'renewing_published', 'enrolling', 'renewing_enrolling']
                             }
                             })
    end

    def initial_employers_reminder_to_publish(new_date)
      Organization.where(:"employer_profile.plan_years" =>
                              {:$elemMatch => {
                                :start_on => new_date,
                                :aasm_state => "draft"
                              }
                              })
    end
  end
end
