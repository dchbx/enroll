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
  embeds_one :coverage_record

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
                :track_create  => true,    # track document creation, default is false
                :track_update  => true,    # track document updates, default is true
                :track_destroy => true

  validates_presence_of :employer_profile_id, :if => Proc.new { |m| m.benefit_sponsor_employer_profile_id.blank? }
  validates_presence_of :benefit_sponsor_employer_profile_id, :if => Proc.new { |m| m.employer_profile_id.blank? }

  field :aasm_state, type: String, default: 'is_active'

  delegate :hbx_id, to: :profile, allow_nil: false

  scope :active, ->{ where(aasm_state: :is_active) }
  aasm do
    state :is_applicant    #Person has requested employer staff role with this company
    state :is_active     #Person has created a company, or been added, or request has been approved
    state :is_closed    #Person employer staff role is not active

    event :approve do
      transitions from: [:is_applicant, :is_active], to: :is_active, :after => [:update_coverage]
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
    if benefit_sponsor_employer_profile_id.present?
      @profile = BenefitSponsors::Organizations::Profile.find(benefit_sponsor_employer_profile_id)
    else
      @profile = EmployerProfile.find(employer_profile_id)
    end
  end

  def fetch_redirection_link
    return nil if aasm_state.to_sym != :is_active

    BenefitSponsors::Engine.routes.url_helpers.profiles_employers_employer_profile_path(profile, tab: 'home').to_s
  end

  def update_coverage
    return unless has_coverage?
    update_person
    create_census_employee
  end

  def update_person
    person.update_attributes(ssn: coverage_record.ssn, gender: coverage_record.gender)
    address = coverage_record.address
    person.addresses.create(kind: 'home', address_1: address.address_1, address_2: address.address_2, city: address.city, state: address.state, zip: address.zip) if address
  end

  def create_census_employee
    benefit_sponsorship = profile.benefit_sponsorships.first
    initial_benefit_packages = benefit_sponsorship.current_benefit_application.benefit_packages if benefit_sponsorship.current_benefit_application.present?
    renewing_benefit_packages = benefit_sponsorship.renewal_benefit_application.benefit_packages if benefit_sponsorship.renewal_benefit_application.present?
    initial_benefit_group_id = initial_benefit_packages.present? && initial_benefit_packages.size > 1 ? initial_benefit_packages.first.id : nil
    renewal_benefit_group_id = renewing_benefit_packages.present? && initial_benefit_packages.size > 1 ? renewing_benefit_packages.first.id : nil
    census_employee = CensusEmployee.new(census_employee_params.merge!(benefit_sponsorship_id: benefit_sponsorship.id,
                                                                       benefit_sponsors_employer_profile_id: benefit_sponsor_employer_profile_id,
                                                                       active_benefit_group_assignment: initial_benefit_group_id,
                                                                       renewal_benefit_group_assignment: renewal_benefit_group_id,
                                                                       hired_on: coverage_record.hired_on,
                                                                       ssn: coverage_record.ssn,
                                                                       gender: coverage_record.gender))
    census_employee.save
  end

  private

  def census_employee_params
    person.attributes.slice('first_name', 'middle_name', 'last_name', 'name_sfx', 'dob', 'ssn', 'gender').merge(
      'address_attributes' => coverage_record.address.attributes.except('_id', 'created_at', 'updated_at', 'tracking_version'),
      'email_attributes' => coverage_record.email.attributes.except('_id', 'created_at', 'updated_at')
    )
  end

  def has_coverage?
    coverage_record.present? && coverage_record.is_applying_coverage
  end
end
