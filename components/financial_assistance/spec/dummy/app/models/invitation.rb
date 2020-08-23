# frozen_string_literal: true

class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  INVITE_TYPES = {
    "census_employee" => "employee_role",
    "broker_role" => "broker_role",
    "broker_agency_staff_role" => "broker_agency_staff_role",
    "employer_staff_role" => "employer_staff_role",
    "assister_role" => "assister_role",
    "csr_role" => "csr_role",
    "hbx_staff_role" => "hbx_staff_role",
    "general_agency_staff_role" => "general_agency_staff_role"
  }.freeze
  ROLES = INVITE_TYPES.values
  SOURCE_KINDS = INVITE_TYPES.keys

  field :role, type: String
  field :source_id, type: BSON::ObjectId
  field :source_kind, type: String
  field :aasm_state, type: String
  field :invitation_email, type: String
  field :invitation_email_type, type: String
  field :benefit_sponsors_employer_profile_id, type: String

  belongs_to :user, optional: true

  validates_presence_of :invitation_email, :allow_blank => false
  validates_presence_of :source_id, :allow_blank => false
  validates :source_kind, :inclusion => { in: SOURCE_KINDS }, :allow_blank => false
  validates :role, :inclusion => { in: ROLES }, :allow_blank => false

  validate :allowed_invite_types


  aasm do
    state :sent, initial: true
    state :claimed

    event :claim do
      transitions from: :sent, to: :claimed, :after => proc { |*args| process_claim!(*args) }
    end
  end
end
