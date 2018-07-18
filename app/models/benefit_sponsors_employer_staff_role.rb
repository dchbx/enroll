class BenefitSponsorsEmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  extend Acapi::Notifiers

  after_update :notify_contact_changed

  field :is_owner, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  field :is_active, type: Boolean, default: true
  field :aasm_state, type: String, default: 'is_active'

  scope :active, -> {where(aasm_state: :is_active)}

  embedded_in :person

  validates_presence_of :employer_profile_id

  aasm do
    state :is_applicant #Person has requested employer staff role with this company
    state :is_active #Person has created a company, or been added, or request has been approved
    state :is_closed #Person employer staff role is not active

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

  def notify_contact_changed
    notify("acapi.info.events.employer.contact_changed", {employer_id: find_employer_profile(self.employer_profile_id).hbx_id, event_name: "contact_changed"})
  end

  def find_employer_profile(employer_profile_id)
    @organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(employer_profile_id)).first
    @employer_profile = @organization.employer_profile
  end
end
