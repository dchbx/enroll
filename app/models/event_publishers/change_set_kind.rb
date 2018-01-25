class EventPublishers::ChangeSetKind
  include Mongoid::Document

  # TODO: Cache these at system startup

  CHANGE_ACTION_KINDS = %w(add remove udpate)

  field :klass_name, type: String
  field :change_action, type: String
  field :change_fields, type: Array, default: []
  field :event_name, type: String
  field :state_machine_name, type: String
  field :state_machine_status, type: String
  field :reason, type: String
  field :submitted_at, type: Time

  validates :change_action,
    allow_blank: false,
    inclusion: {  in: EventPublishers::ChangeSetKind::CHANGE_ACTION_KINDS,
                  message: "%{value} is not a valid change action kind" 
                }

  def matched?

  end

end

class example_change_set_kind
  employer_profile_poc_change = ChangeSetKind.new(
      klass_name: "employer_profile",
      change_action: "update",
      change_fields: %w(address)
    )
  employer_profile_poc_change.save

end
