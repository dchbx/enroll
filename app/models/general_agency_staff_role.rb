class GeneralAgencyStaffRole
  include Mongoid::Document
  include SetCurrentUser
  include MongoidSupport::AssociationProxies
  include AASM

  embedded_in :person
  field :npn, type: String
  field :general_agency_profile_id, type: BSON::ObjectId
  field :aasm_state, type: String, default: "applicant"
  embeds_many :workflow_state_transitions, as: :transitional

  associated_with_one :general_agency_profile, :general_agency_profile_id, "GeneralAgencyProfile"

  validates_presence_of :general_agency_profile_id, :npn
  accepts_nested_attributes_for :person, :workflow_state_transitions
  validates :npn, 
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },    
    uniqueness: true,
    allow_blank: false

  aasm do
    state :applicant, initial: true
    state :active
    state :denied
    state :decertified
    state :general_agency_pending
    state :general_agency_declined
    state :general_agency_terminated

    event :approve, :after => [:record_transition] do
      transitions from: :applicant, to: :general_agency_pending
    end

    event :general_agency_accept, :after => [:record_transition, :send_invitation] do 
      transitions from: :general_agency_pending, to: :active
    end

    event :general_agency_decline, :after => :record_transition do 
      transitions from: :general_agency_pending, to: :general_agency_declined
    end

    event :general_agency_terminate, :after => :record_transition do 
      transitions from: :active, to: :general_agency_terminated
    end

    event :deny, :after => :record_transition do
      transitions from: :applicant, to: :denied
    end

    event :decertify, :after => :record_transition  do
      transitions from: :active, to: :decertified
    end

    event :reapply, :after => :record_transition  do
      transitions from: [:applicant, :decertified, :denied, :general_agency_declined], to: :applicant
    end  

    event :transfer, :after => :record_transition  do
      transitions from: [:active, :general_agency_pending, :general_agency_terminated], to: :applicant
    end  
  end

  def send_invitation
    Invitation.invite_general_agency_staff!(self)
  end

  def current_state
    aasm_state.humanize.titleize
  end

  def applicant?
    aasm_state == 'applicant'
  end

  def active?
    aasm_state == 'active'
  end

  def agency_pending?
    aasm_state == 'general_agency_pending'
  end

  def email
    parent.emails.detect { |email| email.kind == "work" }
  end

  def email_address
    return nil unless email.present?
    email.address
  end

  def parent
    self.person
  end

  class << self
    def find(id)
      return nil if id.blank?
      people = Person.where("general_agency_staff_roles._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].general_agency_staff_roles.detect{|x| x.id.to_s == id.to_s} : nil
    end

    def find_by_npn(npn_value)
      person_records = Person.where("general_agency_staff_roles.npn" => npn_value)
      return [] unless person_records.any?
      person_records.detect do |pr|
        pr.general_agency_staff_roles.present? && pr.general_agency_staff_roles.where(npn: npn_value).first
      end.general_agency_staff_roles.where(npn: npn_value).first
    end
  end

  private
  def latest_transition_time
    if self.workflow_state_transitions.any?
      self.workflow_state_transitions.first.transition_at
    end
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end
