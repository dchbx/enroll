class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  include Validations::Email

  embedded_in :person
  # embedded_in :office_location
  # embedded_in :census_member, class_name: "CensusMember"

  KINDS = %W(home work)

  field :kind, type: String
  field :address, type: String

  validates :address, :email => true, :allow_blank => false
  validates_presence_of  :kind, message: "Choose a type"
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type"

  validates :address,
    presence: true

end
