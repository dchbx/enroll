module Notifier
  class NoticeEvent
    include Mongoid::Document

    field :event_name, type: String
    field :event_model_name, type: String
    field :event_model_id,   type: BSON::ObjectId
    field :event_model_payload, type: Hash
    field :received_at, type: DateTime

    def build_notice
      @notice = NoticeKind.new(event_model_name + '_' + event_name)
    end

    def transmit
      process = distribute_notice.new(@notice)
    end

  end
end


