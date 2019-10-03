class CustomQleEndUserResponse
  include Mongoid::Document

  field :response_submitted, type: String
  field :user_id, type: String
  field :qualifying_life_event_kind_id, type: String
  field :qualifying_life_event_custom_qle_question_id, type: String
end
