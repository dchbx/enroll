class ResidentRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :person

  field :is_applicant, type: Boolean  # Consumer is applying for benefits coverage
  field :is_active, type: Boolean, default: true
  field :bookmark_url, type: String, default: nil

  delegate :hbx_id,           to: :person, allow_nil: true
  delegate :ssn, :ssn=,       to: :person, allow_nil: true
  delegate :dob, :dob=,       to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :dob, :gender

  accepts_nested_attributes_for :person

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  def families
    Family.by_residentRole(self)
  end

  def self.find(resident_role_id)
    resident_role_id = BSON::ObjectId.from_string(resident_role_id) if resident_role_id.is_a? String
    @person_find = Person.where("resident_role._id" => resident_role_id).first.resident_role unless resident_role_id.blank?
  end

  def self.all
    Person.all_resident_roles
  end

  def build_nested_models_for_person
    ["home", "mobile"].each do |kind|
      person.phones.build(kind: kind) if person.phones.select { |phone| phone.kind == kind }.blank?
    end

    (Address::KINDS - ['work']).each do |kind|
      person.addresses.build(kind: kind) if person.addresses.select { |address| address.kind.to_s.downcase == kind }.blank?
    end

    Email::KINDS.each do |kind|
      person.emails.build(kind: kind) if person.emails.select { |email| email.kind == kind }.blank?
    end
  end

  def is_active?
    self.is_active
  end

end
