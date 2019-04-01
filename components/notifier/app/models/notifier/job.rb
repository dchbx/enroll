module Notifier
  class Job
    include Mongoid::Document

    field :description, type: String
    field :priority, type: Integer, default: 50
    field :created_at, type: Time, default: -> { Time.now }

    field :run_at, type: Time
    field :transmit_at, type: Time
    field :expires_at, type: Time

    field :destroy_on_complete, type: Boolean, default: true

    # when this job started processing
    field :started_at, type: Time
    field :completed_at, type: Time

    field :state, type: Symbol, default: :queued

  end
end
