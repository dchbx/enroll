class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :person
  field :is_owner, type: Boolean, default: true
  field :benefit_sponsor_employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  field :is_active, type: Boolean, default: true
  field :aasm_state, type: String, default: 'is_active'
  field :benefit_sponsor_employer_profile_id, type: BSON::ObjectId

  delegate :hbx_id, to: :profile, allow_nil: false

  validates_presence_of :benefit_sponsor_employer_profile_id

  aasm do
    state :is_applicant    #Person has requested employer staff role with this company
    state :is_active     #Person has created a company, or been added, or request has been approved
    state :is_closed	  #Person employer staff role is not active

    event :approve do
      transitions from: [:is_applicant, :is_active], to: :is_active
    end
    event :close_role do
      transitions from: [:is_applicant, :is_active, :is_closed], to: :is_closed
    end
  end

  def profile
    BenefitSponsors::Organizations::Profile.find(benefit_sponsor_employer_profile_id)
  end
end