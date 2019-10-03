class CustomQleAnswer
  include Mongoid::Document

  embedded_in :parent_question, inverse_of: :answers
  embeds_one :custom_qle_question, as: :questionable
  embeds_many :responses

  accepts_nested_attributes_for :custom_qle_question
  accepts_nested_attributes_for :responses

  field :content, type: String
end
