# frozen_string_literal: true

class EventResponse
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :lawful_presence_determination
  embedded_in :consumer_role

  field :received_at, type: DateTime
  field :body, type: String #the payload[:body] in the event response

end
