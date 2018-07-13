class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  include Validations::Email

  # TODO
  # embedded_in :person
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

  def blank?
    address.blank?
  end

  def match(another_email)
    return false if another_email.nil?
    attrs_to_match = [:kind, :address]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_email) }
  end

  def attribute_matches?(attribute, other)
    self[attribute] == other[attribute]
  end

end
