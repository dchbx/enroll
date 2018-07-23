class AchRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  ROUTING_NUMBER_LENGTH = 9

  field :routing_number, type: String
  field :account_number, type: String
  field :bank_name, type: String

  validates_uniqueness_of :routing_number
  validates_presence_of :routing_number, :bank_name
  validates :routing_number, length: { is: ROUTING_NUMBER_LENGTH }
  validates_confirmation_of :routing_number

  index({routing_number: 1}, { unique: true })
end
