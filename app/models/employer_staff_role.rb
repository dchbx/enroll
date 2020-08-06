# frozen_string_literal: true

class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include ::BenefitSponsors::Concerns::Observable
  include Mongoid::History::Trackable

  add_observer ::BenefitSponsors::Observers::EmployerStaffRoleObserver.new, :contact_changed?
  after_create :notify_observers
  after_update :notify_observers

  embedded_in :person

  field :is_owner, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  field :is_active, type: Boolean, default: true
  field :benefit_sponsor_employer_profile_id, type: BSON::ObjectId

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create => true,    # track document creation, default is false
                :track_update => true,    # track document updates, default is true
                :track_destroy => true

  validates_presence_of :employer_profile_id, :if => proc { |m| m.benefit_sponsor_employer_profile_id.blank? }
  validates_presence_of :benefit_sponsor_employer_profile_id, :if => proc { |m| m.employer_profile_id.blank? }

  field :aasm_state, type: String, default: 'is_active'

  delegate :hbx_id, to: :profile, allow_nil: false

  scope :active, ->{ where(aasm_state: :is_active) }
  aasm do
    state :is_applicant    #Person has requested employer staff role with this company
    state :is_active     #Person has created a company, or been added, or request has been approved
    state :is_closed    #Person employer staff role is not active

    event :approve do
      transitions from: [:is_applicant, :is_active], to: :is_active
    end
    event :close_role do
      transitions from: [:is_applicant, :is_active, :is_closed], to: :is_closed
    end
  end

  def current_state
    aasm_state.humanize.titleize
  end

  def profile
    return @profile if defined? @profile
    @profile = if benefit_sponsor_employer_profile_id.present?
                 BenefitSponsors::Organizations::Profile.find(benefit_sponsor_employer_profile_id)
               else
                 EmployerProfile.find(employer_profile_id)
               end
  end
end
