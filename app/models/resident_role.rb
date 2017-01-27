class ResidentRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  delegate :hbx_id,           to: :person, allow_nil: true
  delegate :ssn, :ssn=,       to: :person, allow_nil: true
  delegate :dob, :dob=,       to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :dob, :gender

  accepts_nested_attributes_for :person

end
