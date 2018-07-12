class ApplicationEventKind
  include Mongoid::Document

  # PERSON_CREATED_EVENT_NAME = "acapi.info.events.individual.created"

  RESOURCE_NAME_KINDS = %w(
                          family
                          employer
                          employee_role
                          consumer_role
                          broker_agency_profile
                          broker_role
                          issuer_profile
                          general_agent_profile
                        )

  field :hbx_id, type: String
  field :title, type: String
  field :description, type: String
  field :resource_name, type: String
  field :event_name, type: String

  embeds_many :notice_triggers
  accepts_nested_attributes_for :notice_triggers

  validates_presence_of :title, :resource_name, :event_name
  validates :resource_name,
    inclusion: { in: RESOURCE_NAME_KINDS, message: "%{value} is not a defined resource name" }

  def self.application_events_for(event_name)
    resource_name, event_name = ApplicationEventMapper.extract_event_parts(event_name)
    self.where(event_name: event_name, resource_name: resource_name)
  end

  def execute_notices(event_name, payload)
    finder_mapping = ApplicationEventMapper.lookup_resource_mapping(event_name)
    if finder_mapping.nil?
      # LOG AN ERROR ABOUT A BOGUS EVENT WHERE YOU CAN'T FIND THINGS
      return
    end
    object_event_was_about = finder_mapping.mapped_class.send(finder_mapping.search_method, payload[finder_mapping.identifier_key.to_s])
    notice_triggers.each do |trigger|
      trigger.publish(object_event_was_about, self.event_name)
    end
    # Use the object and the application event kind to do your stuff
  end

  def resource_name=(new_resource_name)
    write_attribute(:resource_name, stringify(new_resource_name))
    update_key
  end

  def event_name=(new_event_name)
    write_attribute(:event_name, stringify(new_event_name))
    update_key
  end

  def resource_events
    resource_name.camelize.constantize
  end

private
  def update_key
    if resource_name.present? && event_name.present?
      write_attribute(:key, [resource_name, event_name].compact.join("."))
    end
  end

  def stringify(value)
    case value
    when Symbol
      value.to_s
    when String
      value.downcase
    else
      # assume this is a class instance
      value.underscore
    end
  end

end

