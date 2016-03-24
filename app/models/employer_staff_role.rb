class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :person
  field :is_owner, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  validates_presence_of :employer_profile_id
  field :aasm_state, type: String, default: 'is_active'
  scope :active, ->{ where(aasm_state: :is_active) }
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

  def current_state
    aasm_state.humanize.titleize
  end

end