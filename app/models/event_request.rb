class EventRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :lawful_presence_determination
  embedded_in :consumer_role

  field :requested_at, type: DateTime
  field :body, type: String #the payload[:body] in the event request

end