module StateTransitionPublisher
  include Acapi::Notifiers

  def self.included(base)
    base.class_eval do
      aasm do
        after_all_transitions :publish_transition
      end
    end
  end

  def publish_transition
    resource_mapping = ApplicationEventMapper.map_resource(self.class)
    event_name = ApplicationEventMapper.map_event_name(resource_mapping, aasm.current_event)
    notify(event_name, {resource_mapping.identifier_key => self.send(resource_mapping.identifier_method).to_s})
  end
end


# def publish_transition
#     resource_mapping = ApplicationEventMapper.map_resource(self.class)
#     'EmployerProfile', 'plan_match_notifier'

#     event_name = ApplicationEventMapper.map_event_name(resource_mapping, aasm.current_event)
#     notify(event_name, {resource_mapping.identifier_key => self.send(resource_mapping.identifier_method).to_s})
#   end