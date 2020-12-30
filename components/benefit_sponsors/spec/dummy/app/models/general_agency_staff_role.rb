# frozen_string_literal: true

class GeneralAgencyStaffRole
  include Mongoid::Document
  include AASM
  include MongoidSupport::AssociationProxies

  embedded_in :person
  field :npn, type: String
  field :general_agency_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_general_agency_profile_id, type: BSON::ObjectId
  field :aasm_state, type: String, default: "applicant"
  field :is_primary, type: Boolean, default: false

  associated_with_one :general_agency_profile, :benefit_sponsors_general_agency_profile_id, "::BenefitSponsors::Organizations::GeneralAgencyProfile"

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

    event :approve, :after => :update_general_agency_profile do
      transitions from: [:applicant, :general_agency_pending], to: :active
    end

    event :deny, :after => :update_general_agency_profile do
      transitions from: :applicant, to: :denied
    end

    event :decertify, :after => :update_general_agency_profile do
      transitions from: :active, to: :decertified
    end

    # Attempt to achieve or return to good standing with HBX
    event :reapply, :after => :record_transition  do
      transitions from: [:applicant, :decertified, :denied], to: :applicant
    end

    event :general_agency_terminate do
      transitions from: [:active, :general_agency_pending], to: :general_agency_terminated
    end

    event :general_agency_pending do
      transitions from: [:general_agency_terminated, :applicant], to: :general_agency_pending
    end
  end

  def agency_pending?
    aasm_state == "general_agency_pending"
  end

  def is_open?
    agency_pending? || active?
  end

  class << self

    def general_agencies_matching_search_criteria(search_str)
      Person.exists(general_agency_staff_roles: true).search_first_name_last_name_npn(search_str).where("general_agency_staff_roles.aasm_state" => "active")
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

  def record_transition
  end
end
