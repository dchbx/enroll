class CustomQleQuestion
  include Mongoid::Document

  embedded_in :qualifying_life_event_kind 
  embeds_many :custom_qle_responses

  field :content, type: String

  accepts_nested_attributes_for :custom_qle_responses
end
