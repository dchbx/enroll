class CensusEmployee < CensusMember
  include AASM
  include Sortable
  include Searchable
  include Autocomplete
  include Config::AcaModelConcern
  include BenefitSponsors::Concerns::Observable
  include ::BenefitSponsors::ModelEvents::CensusEmployee

  require 'roo'

  EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
  EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated cobra_terminated rehired)
  ELIGIBLE_STATES = %w(eligible newly_designated_eligible cobra_eligible employee_termination_pending cobra_termination_pending)
  PENDING_STATES = %w(employee_termination_pending cobra_termination_pending)
  EMPLOYMENT_ACTIVE_ONLY = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked)

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

  belongs_to :benefit_sponsorship, class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship", optional: true

  embeds_many :workflow_state_transitions, as: :transitional

  after_save :notify_on_save

  add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_census_employee_events]

  accepts_nested_attributes_for :census_dependents, :benefit_group_assignments

  scope :by_benefit_package_and_assignment_on,->(benefit_package, effective_on) {
    where(:"benefit_group_assignments" => { :$elemMatch => {
      :start_on => effective_on,
      :benefit_package_id => benefit_package.id
      }})
  }

  scope :benefit_application_assigned,     ->(benefit_application) { where(:"benefit_group_assignments.benefit_package_id".in => benefit_application.benefit_packages.pluck(:_id)) }
  scope :benefit_application_unassigned,   ->(benefit_application) { where(:"benefit_group_assignments.benefit_package_id".nin => benefit_application.benefit_packages.pluck(:_id)) }


  scope :non_terminated,     ->{ where(:aasm_state.nin => EMPLOYMENT_TERMINATED_STATES) }
  scope :active,             ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
  scope :pending,           ->{ any_in(aasm_state: PENDING_STATES) }
  scope :non_term_and_pending,->{ where(:aasm_state.nin => (EMPLOYMENT_TERMINATED_STATES + PENDING_STATES)) }
  scope :non_business_owner, ->{ where(is_business_owner: false) }
  scope :benefit_application_assigned,     ->(benefit_application) { where(:"benefit_group_assignments.benefit_package_id".in => benefit_application.benefit_packages.pluck(:_id)) }
  scope :benefit_application_unassigned,   ->(benefit_application) { where(:"benefit_group_assignments.benefit_package_id".nin => benefit_application.benefit_packages.pluck(:_id)) }
  scope :non_term_and_pending,->{ where(:aasm_state.nin => (EMPLOYMENT_TERMINATED_STATES + PENDING_STATES)) }

  scope :eligible_without_term_pending, ->{ any_in(aasm_state: (ELIGIBLE_STATES - PENDING_STATES)) }
  scope :active_alone,      ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_ONLY) }
  scope :by_ssn,            ->(ssn) { where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).and(:encrypted_ssn.nin => ["", nil]) }

  scope :by_benefit_package_and_assignment_on_or_later,->(benefit_package, effective_on) do
    where(
      :benefit_group_assignments => {
        :$elemMatch => {
          :start_on.gte => effective_on,
          :benefit_package_id => benefit_package.id,
        }
      }
    )
  end

  scope :census_employees_active_on, -> (date) {
    where(
        "$or" => [
            {"employment_terminated_on" => nil},
            {"employment_terminated_on" => {"$gte" => date}}
        ]
    )
  }

  scope :eligible_for_renewal_under_package, ->(benefit_package, package_start, package_end, new_effective_date) {
    where(:"benefit_group_assignments" => {
        :$elemMatch => {
          :benefit_package_id => benefit_package.id,
          :start_on => { "$gte" => package_start },
          "$or" => [
            {"end_on" => nil},
            {"end_on" => {"$exists" => false}},
            {"end_on" => package_end}
          ]
        },
      },
      "$or" => [
        {"employment_terminated_on" => nil},
        {"employment_terminated_on" => {"$exists" => false}},
        {"employment_terminated_on" => {"$gte" => new_effective_date}}
      ]
    )
  }

  scope :employees_for_benefit_application_sponsorship, ->(benefit_application) {
    new_effective_date = benefit_application.start_on
    benefit_sponsorship_id = benefit_application.benefit_sponsorship.id
    where(
      "hired_on" => {"$lte" => new_effective_date},
      "benefit_sponsorship_id" => benefit_sponsorship_id,
      "$or" => [
        {"employment_terminated_on" => nil},
        {"employment_terminated_on" => {"$exists" => false}},
        {"employment_terminated_on" => {"$gte" => new_effective_date}}
      ]
    )
  }

  def self.lacking_predecessor_assignment_for_application_as_of(predecessor_application, new_effective_date)
    package_ids = predecessor_application.benefit_packages.map(&:id)
    package_start = predecessor_application.start_on
    package_end = predecessor_application.end_on
    benefit_sponsorship_id = predecessor_application.benefit_sponsorship.id
    CensusEmployee.where(
      "hired_on" => {"$lte" => new_effective_date},
      "benefit_sponsorship_id" => benefit_sponsorship_id,
      "$or" => [
        {"employment_terminated_on" => nil},
        {"employment_terminated_on" => {"$exists" => false}},
        {"employment_terminated_on" => {"$gte" => new_effective_date}}
      ],
      "benefit_group_assignments" => {
        "$not" => {
          "$elemMatch" => {
            "benefit_package_id" => {"$in" => package_ids},
            "start_on" => { "$gte" => package_start },
            "$or" => [
              {"end_on" => nil},
              {"end_on" => {"$exists" => false}},
              {"end_on" => package_end}
            ]
          }
        }
      }
    )
  end

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

  def is_active?
    EMPLOYMENT_ACTIVE_STATES.include?(aasm_state)
  end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.class.to_s.match(/EmployerProfile/)
      self.benefit_sponsors_employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    return @employer_profile = BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.find(self.employer_profile_id) if (self.employer_profile_id.present? && self.benefit_sponsors_employer_profile_id.blank?)
    return nil if self.benefit_sponsorship.blank? # Need this for is_case_old?
    @employer_profile = self.benefit_sponsorship.organization.employer_profile
  end

  def is_case_old?(profile=nil)
    if profile.present?
      profile.is_a?(EmployerProfile)
    else
      benefit_sponsors_employer_profile_id.blank?
    end
  end

  def employee_role
    return nil if self.employee_role_id.nil?
    return @employee_role if @employee_role
    @employee_role = EmployeeRole.find(self.employee_role_id)
  end

  def family
    return nil if employee_role.blank?

    person_rec = employee_role.person
    person_rec.primary_family
  end

  def benefit_sponsorship=(benefit_sponsorship)
    return "expected Benefit Sponsorship" unless defined?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
    self.benefit_sponsorship_id = benefit_sponsorship.id
    self.benefit_sponsors_employer_profile_id = benefit_sponsorship.profile.id
    @benefit_sponsorship = benefit_sponsorship
  end

  def qle_30_day_eligible?
    is_inactive? && (TimeKeeper.date_of_record - employment_terminated_on).to_i < 30
  end

  def benefit_package_assignment_for(benefit_package)
    benefit_group_assignments.effective_on(benefit_package.effective_period.min).detect do |assignment|
      assignment.benefit_package_id == benefit_package.id
    end
  end

  def renewal_benefit_group_assignment
    return benefit_group_assignments.order_by(:created_at.desc).detect{ |assignment| assignment.plan_year &. is_renewing? } if is_case_old?
    benefit_group_assignments.order_by(:created_at.desc).detect{ |assignment| assignment.benefit_application &. is_renewing? }
  end

  def inactive_benefit_group_assignments
    # TODO: "is_active" depracated
    benefit_group_assignments.reject(&:is_active?)
  end

  def benefit_package_assignment_for(benefit_package)
    benefit_group_assignments.effective_on(benefit_package.effective_period.min).detect do |assignment|
      assignment.benefit_package_id == benefit_package.id
    end
  end

 def waived?
    bga = renewal_benefit_group_assignment || active_benefit_group_assignment
    return bga.present? ? bga&.hbx_enrollment&.aasm_state == 'coverage_waived' : false
  end

  def is_waived_under?(benefit_application)
    assignment_by_application = [renewal_benefit_group_assignment, active_benefit_group_assignment].compact.detect do |assignment|
      assignment.benefit_application && (assignment.benefit_application == benefit_application)
    end
    return false if assignment_by_application.blank? || assignment_by_application.hbx_enrollment.blank?
    assignment_by_application.hbx_enrollment.is_coverage_waived?
  end

  def renewal_benefit_group_assignment=(renewal_package_id)
    benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.where(
      :"benefit_packages._id" => renewal_package_id
    ).first || employer_profile.active_benefit_sponsorship.renewal_benefit_application

    if benefit_application.present?
      benefit_packages = renewal_package_id.present? ? [benefit_application.benefit_packages.find(renewal_package_id)] : benefit_application.benefit_packages
    end

    if benefit_packages.present? && (renewal_benefit_group_assignment.blank? || !benefit_packages.map(&:id).include?(renewal_benefit_group_assignment.benefit_package.id))
      add_renew_benefit_group_assignment(benefit_packages)
    end
  end

  def create_benefit_group_assignment(benefit_packages, off_cycle = false)
    assignment = off_cycle ? off_cycle_benefit_group_assignment : active_benefit_group_assignment
    if benefit_packages.present?
      if assignment.present?
        end_date, new_start_on =
          if assignment.start_on >= TimeKeeper.date_of_record
            [assignment.start_on, benefit_packages.first.start_on]
          else
            [TimeKeeper.date_of_record.prev_day, TimeKeeper.date_of_record]
          end
        assignment.end_benefit(end_date)
      end
      add_benefit_group_assignment(benefit_packages.first, new_start_on || benefit_packages.first.start_on, benefit_packages.first.end_on)
    end
  end

  def add_renew_benefit_group_assignment(renewal_benefit_packages)
    if renewal_benefit_packages.present?
      if renewal_benefit_group_assignment.present?
        end_date, new_start_on =
          if renewal_benefit_group_assignment.start_on >= TimeKeeper.date_of_record
            [renewal_benefit_group_assignment.start_on, renewal_benefit_packages.first.start_on]
          else
            [TimeKeeper.date_of_record.prev_day, TimeKeeper.date_of_record]
          end
        renewal_benefit_group_assignment.end_benefit(end_date)
      end
      add_benefit_group_assignment(renewal_benefit_packages.first, new_start_on || renewal_benefit_packages.first.start_on, renewal_benefit_packages.first.end_on)
    end
  end

  def add_benefit_group_assignment(new_benefit_group, start_on = nil, end_on = nil)
    raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitSponsors::BenefitPackages::BenefitPackage)
    reset_active_benefit_group_assignments(new_benefit_group)
    benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: (start_on || new_benefit_group.start_on))
  end

  def reset_active_benefit_group_assignments(new_benefit_group)
    benefit_group_assignments.select { |assignment| assignment.is_active? }.each do |benefit_group_assignment|
      benefit_group_assignment.end_on = [new_benefit_group.start_on - 1.day, benefit_group_assignment.start_on].max
    end
  end

  def published_benefit_group_assignment
    benefit_group_assignments.detect do |benefit_group_assignment|
      benefit_group_assignment.benefit_group.is_active && benefit_group_assignment.benefit_group.plan_year.employees_are_matchable?
    end
  end

  def coverage_effective_on(package = nil)
    package = possible_benefit_package if (package.blank? || package.is_conversion?) # cautious
    if package.present?
      effective_on_date = package.effective_on_for(hired_on)
      if newly_designated_eligible? || newly_designated_linked?
        effective_on_date = [effective_on_date, newly_eligible_earlist_eligible_date].max
      end
      effective_on_date
    end
  end

  def new_hire_enrollment_period
    start_on = [hired_on, TimeKeeper.date_according_to_exchange_at(created_at)].max
    end_on = earliest_eligible_date.present? ? [start_on + 30.days, earliest_eligible_date].max : (start_on + 30.days)
    (start_on.beginning_of_day)..(end_on.end_of_day)
  end

  def earliest_eligible_date
    benefit_group_assignment = renewal_benefit_group_assignment || active_benefit_group_assignment

    if benefit_group_assignment
      benefit_group_assignment.benefit_group.eligible_on(hired_on)
    end
  end

  def terminate_employment(employment_terminated_on)
    begin
      terminate_employment!(employment_terminated_on)
    rescue => e
      Rails.logger.error { e }
      false
    else
      self
    end
  end

  def terminate_employee_enrollments(employment_terminated_on)
    term_eligible_active_enrollments = active_benefit_group_enrollments.show_enrollments_sans_canceled.non_terminated if active_benefit_group_enrollments.present?
    term_eligible_renewal_enrollments = renewal_benefit_group_enrollments.show_enrollments_sans_canceled.non_terminated if renewal_benefit_group_enrollments.present?
    enrollments = (Array.wrap(term_eligible_active_enrollments) + Array.wrap(term_eligible_renewal_enrollments)).compact

    enrollments.each do |enrollment|
      if enrollment.effective_on > self.coverage_terminated_on
        enrollment.cancel_coverage!(self.coverage_terminated_on) if enrollment.may_cancel_coverage?
      else
        if self.coverage_terminated_on < TimeKeeper.date_of_record
          enrollment.terminate_coverage!(self.coverage_terminated_on) if enrollment.may_terminate_coverage?
        else
          enrollment.schedule_coverage_termination!(self.coverage_terminated_on) if enrollment.may_schedule_coverage_termination?
        end
      end
    end
  end


  def terminate_employment!(employment_terminated_on)
    if may_schedule_employee_termination?
      self.employment_terminated_on = employment_terminated_on
      self.coverage_terminated_on = earliest_coverage_termination_on(employment_terminated_on)
    end

    if employment_terminated_on < TimeKeeper.date_of_record
      if may_terminate_employee_role?
        terminate_employee_role!
        # perform_employer_plan_year_count
      else
        message = "Error terminating employment: unable to terminate employee role for: #{self.full_name}"
        Rails.logger.error { message }
        raise CensusEmployeeError, message
      end
    else # Schedule Future Terminations as employment_terminated_on is in the future
      schedule_employee_termination! if may_schedule_employee_termination?
    end
    terminate_employee_enrollments(employment_terminated_on)
    self
  end

  def earliest_coverage_termination_on(employment_termination_date, submitted_date = TimeKeeper.date_of_record)
    employment_based_date = employment_termination_date.end_of_month
    submitted_based_date  = TimeKeeper.date_of_record.
                              advance(Settings.
                                          aca.
                                          shop_market.
                                          retroactive_coverage_termination_maximum
                                          .to_hash
                                        ).end_of_month

    [employment_based_date, submitted_based_date].max
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event
    )
  end

  def active_benefit_group
    if active_benefit_group_assignment.present?
      active_benefit_group_assignment.benefit_package
    end
  end

  def published_benefit_group
    published_benefit_group_assignment.benefit_group if published_benefit_group_assignment
  end

  def renewal_published_benefit_group
    if renewal_benefit_group_assignment && renewal_benefit_group_assignment.benefit_group.plan_year.employees_are_matchable?
      renewal_benefit_group_assignment.benefit_group
    end
  end

  def active_benefit_group_enrollments
    return nil if employee_role.blank?
    family = Family.where({
      "households.hbx_enrollments" => {:"$elemMatch" => {
        :"sponsored_benefit_package_id".in => [active_benefit_group.try(:id)].compact,
        :"employee_role_id" => self.employee_role_id}
      }
    }).first

    return [] if family.blank?

    family.active_household.hbx_enrollments.where(
      :"sponsored_benefit_package_id".in => [active_benefit_group.try(:id)].compact,
      :"employee_role_id" => self.employee_role_id,
      :"aasm_state".ne => "shopping"
    )
  end

  def renewal_benefit_group_enrollments
    return nil if employee_role.blank?
    family = Family.where({
      "households.hbx_enrollments" => {:"$elemMatch" => {
        :"sponsored_benefit_package_id".in => [renewal_published_benefit_group.try(:id)].compact,
        :"employee_role_id" => self.employee_role_id }
      }
    }).first

    return [] if family.blank?

    family.active_household.hbx_enrollments.where(
      :"sponsored_benefit_package_id".in => [renewal_published_benefit_group.try(:id)].compact,
      :"employee_role_id" => self.employee_role_id,
      :"aasm_state".ne => "shopping"
    )
  end

  def benefit_package_assignment_on(effective_date)
    benefit_group_assignments.effective_on(effective_date).first
  end

  def assign_to_benefit_package(benefit_package, assignment_on)
    return if benefit_package.blank?

    benefit_group_assignments.create(
        start_on: assignment_on,
        end_on:   benefit_package.effective_period.max,
        benefit_package: benefit_package,
    )
  end

  def active_benefit_group_assignment=(benefit_package_id)
    benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.where(
      :"benefit_packages._id" => benefit_package_id
    ).first || employer_profile.active_benefit_sponsorship.current_benefit_application

    if benefit_application.present?
      benefit_packages = benefit_package_id.present? ? [benefit_application.benefit_packages.find(benefit_package_id)] : benefit_application.benefit_packages
    end

    if benefit_packages.present? && (active_benefit_group_assignment.blank? || !benefit_packages.map(&:id).include?(active_benefit_group_assignment.benefit_package.id))
      create_benefit_group_assignment(benefit_packages)
    end
  end


  def active_benefit_group_assignment(coverage_date = TimeKeeper.date_of_record)
    benefit_package_assignment_on(coverage_date) || benefit_group_assignments.reject { |bga| bga.activated_at.present? }.sort_by(&:start_on).reverse.last
  end

  def renewal_benefit_group_assignment
    benefit_group_assignments.order_by(:'updated_at'.desc).detect{ |assignment| assignment.benefit_application && assignment.benefit_application.is_renewing? }
  end
end
