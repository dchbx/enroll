# frozen_string_literal: true

class GeneralAgencyStaffRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies
  include AASM
  include Mongoid::History::Trackable

  embedded_in :person
  field :npn, type: String
  field :general_agency_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_general_agency_profile_id, type: BSON::ObjectId
  field :aasm_state, type: String, default: "applicant"
  field :is_primary, type: Boolean, default: false

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create => true,    # track document creation, default is false
                :track_update => true,    # track document updates, default is true
                :track_destroy => true

  embeds_many :workflow_state_transitions, as: :transitional

  associated_with_one :general_agency_profile, :benefit_sponsors_general_agency_profile_id, "::BenefitSponsors::Organizations::GeneralAgencyProfile"

  validates_presence_of :npn
  validates_presence_of :benefit_sponsors_general_agency_profile_id, :if => proc { |m| m.general_agency_profile_id.blank? }
  validates_presence_of :general_agency_profile_id, :if => proc { |m| m.benefit_sponsors_general_agency_profile_id.blank? }

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
    state :general_agency_declined
    state :general_agency_terminated
    state :general_agency_pending

    event :approve, :after => [:record_transition, :send_invitation, :update_general_agency_profile] do
      transitions from: [:applicant, :general_agency_pending], to: :active
    end

    event :deny, :after => [:record_transition, :update_general_agency_profile]  do
      transitions from: :applicant, to: :denied
    end

    event :decertify, :after => [:record_transition, :update_general_agency_profile] do
      transitions from: :active, to: :decertified
    end

    # Attempt to achieve or return to good standing with HBX
    event :reapply, :after => :record_transition  do
      transitions from: [:applicant, :decertified, :denied], to: :applicant
    end

    event :general_agency_terminate, :after => :record_transition do
      transitions from: [:active, :general_agency_pending], to: :general_agency_terminated
    end

    event :general_agency_active, :after => :record_transition do
      transitions from: :general_agency_terminated, to: :active
    end

    event :general_agency_pending, :after => :record_transition do
      transitions from: [:general_agency_terminated, :applicant], to: :general_agency_pending
    end
  end

  def general_agency_profile
    return @general_agency_profile if defined? @general_agency_profile
    if self.benefit_sponsors_general_agency_profile_id.nil?
      @general_agency_profile = ::GeneralAgencyProfile.find(general_agency_profile_id) if has_general_agency_profile?
    else
      @general_agency_profile = ::BenefitSponsors::Organizations::Organization.where(:"profiles._id" => benefit_sponsors_general_agency_profile_id).first.general_agency_profile if has_general_agency_profile?
    end
  end

  def has_general_agency_profile?
    self.benefit_sponsors_general_agency_profile_id.present? || self.general_agency_profile_id.present?
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

  def agency_pending?
    aasm_state == "general_agency_pending"
  end

  def is_open?
    agency_pending? || active?
  end

  def fetch_redirection_link
    return nil if aasm_state.to_sym != :active

    if general_agency_profile.is_a? BenefitSponsors::Organizations::GeneralAgencyProfile
      BenefitSponsors::Engine.routes.url_helpers.profiles_general_agencies_general_agency_profile_path(general_agency_profile, tab: 'home').to_s
    else
      Rails.application.routes.url_helpers.general_agencies_profile_path(general_agency_profile).to_s
    end
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

  def update_general_agency_profile
    return unless is_primary
    case aasm.to_state
    when :active
      general_agency_profile.approve!
    when :denied
      general_agency_profile.reject!
    when :decertified
      general_agency_profile.close!
    end
  end

  def latest_transition_time
    self.workflow_state_transitions.first.transition_at if self.workflow_state_transitions.any?
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event
    )
  end
end
