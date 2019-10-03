class CustomQleResponse
  include Mongoid::Document

  ACTIONS_TO_TAKE = %w[accepted declined to_question_2 call_center]
  
  embedded_in :custom_qle_question

  field :content, type: String
  field :action_to_take, type: String
end
