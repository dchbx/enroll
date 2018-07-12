class CensusEmployee < CensusMember
  include AASM
  include Sortable
  include Searchable
  include Autocomplete
  include Config::AcaModelConcern
  
  require 'roo'
  
  EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
  EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated cobra_terminated rehired)

  field :is_business_owner, type: Boolean, default: false
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :coverage_terminated_on, type: Date
  field :aasm_state, type: String
  field :expected_selection, type: String, default: "enroll"

  # Employer for this employee
  field :employer_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_employer_profile_id, type: BSON::ObjectId

  # Employee linked to this roster record
  field :employee_role_id, type: BSON::ObjectId
  field :cobra_begin_date, type: Date

  embeds_many :census_dependents,
    cascade_callbacks: true,
    validate: true

  embeds_many :benefit_group_assignments,
    cascade_callbacks: true,
    validate: true

  belongs_to :benefit_sponsorship, class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

  accepts_nested_attributes_for :census_dependents, :benefit_group_assignments

  scope :by_benefit_package_and_assignment_on,->(benefit_package, effective_on, is_active) {
    where(:"benefit_group_assignments" => { :$elemMatch => {
      :start_on => effective_on,
      :benefit_package_id => benefit_package.id, :is_active => is_active
      }})
  }

  scope :non_terminated,     ->{ where(:aasm_state.nin => EMPLOYMENT_TERMINATED_STATES) }
  scope :active,             ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
  scope :non_business_owner, ->{ where(is_business_owner: false) }

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def employer_profile=(new_employer_profile)
    self.employer_profile_id = new_employer_profile._id
    self.benefit_sponsors_employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  aasm do
    state :eligible, initial: true
    state :cobra_eligible
    state :newly_designated_eligible    # congressional employee state with certain new hire rules
    state :employee_role_linked
    state :cobra_linked
    state :newly_designated_linked
    state :cobra_termination_pending
    state :employee_termination_pending
    state :employment_terminated
    state :cobra_terminated
    state :rehired

    event :newly_designate, :after => :record_transition do
      transitions from: :eligible, to: :newly_designated_eligible
      transitions from: :employee_role_linked, to: :newly_designated_linked
    end

    event :rebase_new_designee, :after => :record_transition do
      transitions from: :newly_designated_eligible, to: :eligible
      transitions from: :newly_designated_linked, to: :employee_role_linked
    end

    event :rehire_employee_role, :after => :record_transition do
      transitions from: [:employment_terminated, :cobra_eligible, :cobra_linked, :cobra_terminated], to: :rehired
    end

    event :elect_cobra, :guard => :have_valid_date_for_cobra?, :after => :record_transition do
      transitions from: :employment_terminated, to: :cobra_linked, :guard => :has_employee_role_linked?, after: :build_hbx_enrollment_for_cobra
      transitions from: :employment_terminated, to: :cobra_eligible
    end

    event :link_employee_role, :after => :record_transition do
      transitions from: :eligible, to: :employee_role_linked, :guard => :has_benefit_group_assignment?
      transitions from: :cobra_eligible, to: :cobra_linked, guard: :has_benefit_group_assignment?
      transitions from: :newly_designated_eligible, to: :newly_designated_linked, :guard => :has_benefit_group_assignment?
    end

    event :delink_employee_role, :guard => :has_no_hbx_enrollments?, :after => :record_transition do
      transitions from: :employee_role_linked, to: :eligible, :after => :clear_employee_role
      transitions from: :newly_designated_linked, to: :newly_designated_eligible, :after => :clear_employee_role
      transitions from: :cobra_linked, to: :cobra_eligible, after: :clear_employee_role
    end

    event :schedule_employee_termination, :after => :record_transition do
      transitions from: [:employee_termination_pending, :eligible, :employee_role_linked, :newly_designated_eligible, :newly_designated_linked], to: :employee_termination_pending
      transitions from: [:cobra_termination_pending, :cobra_eligible, :cobra_linked],  to: :cobra_termination_pending
    end

    event :terminate_employee_role, :after => :record_transition do
      transitions from: [:eligible, :employee_role_linked, :employee_termination_pending, :newly_designated_eligible, :newly_designated_linked], to: :employment_terminated
      transitions from: [:cobra_eligible, :cobra_linked, :cobra_termination_pending],  to: :cobra_terminated
    end

    event :reinstate_eligibility, :after => [:record_transition] do
      transitions from: :employment_terminated, to: :employee_role_linked, :guard => :has_employee_role_linked?
      transitions from: :employment_terminated,  to: :eligible
      transitions from: :cobra_terminated, to: :cobra_linked, :guard => :has_employee_role_linked?
      transitions from: :cobra_terminated, to: :cobra_eligible
    end

  end
end