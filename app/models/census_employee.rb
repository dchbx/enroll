class CensusEmployee < CensusMember
  include AASM
  include Sortable
  include Searchable
  # include Validations::EmployeeInfo
  include Autocomplete
  require 'roo'

  EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending)
  EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated rehired)

  field :is_business_owner, type: Boolean, default: false
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :coverage_terminated_on, type: Date
  field :aasm_state, type: String

  # Employer for this employee
  field :employer_profile_id, type: BSON::ObjectId

  # Employee linked to this roster record
  field :employee_role_id, type: BSON::ObjectId

  embeds_many :census_dependents,
    cascade_callbacks: true,
    validate: true

  embeds_many :benefit_group_assignments,
    cascade_callbacks: true,
    validate: true

  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :census_dependents, :benefit_group_assignments

  validates_presence_of :employer_profile_id, :ssn, :dob, :hired_on, :is_business_owner
  validate :check_employment_terminated_on
  validate :active_census_employee_is_unique
  validate :allow_id_info_changes_only_in_eligible_state
  validate :check_census_dependents_relationship
  validate :no_duplicate_census_dependent_ssns
  validate :check_hired_on_before_dob
  after_update :update_hbx_enrollment_effective_on_by_hired_on

  before_save :assign_default_benefit_package
  before_save :allow_nil_ssn_updates_dependents

  index({aasm_state: 1})
  index({last_name: 1})
  index({dob: 1})

  index({encrypted_ssn: 1, dob: 1, aasm_state: 1})
  index({employee_role_id: 1}, {sparse: true})
  index({employer_profile_id: 1, encrypted_ssn: 1, aasm_state: 1})
  index({employer_profile_id: 1, last_name: 1, first_name: 1, hired_on: -1 })
  index({employer_profile_id: 1, hired_on: 1, last_name: 1, first_name: 1 })
  index({employer_profile_id: 1, is_business_owner: 1})

  index({"benefit_group_assignments._id" => 1})
  index({"benefit_group_assignments.benefit_group_id" => 1})
  index({"benefit_group_assignments.aasm_state" => 1})


  scope :active,      ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
  scope :terminated,  ->{ any_in(aasm_state: EMPLOYMENT_TERMINATED_STATES) }
  scope :non_terminated, -> { where(:aasm_state.nin => EMPLOYMENT_TERMINATED_STATES) }

  #TODO - need to add fix for multiple plan years
  # scope :enrolled,    ->{ where("benefit_group_assignments.aasm_state" => ["coverage_selected", "coverage_waived"]) }
  # scope :covered,     ->{ where( "benefit_group_assignments.aasm_state" => "coverage_selected" ) }
  # scope :waived,      ->{ where( "benefit_group_assignments.aasm_state" => "coverage_waived" ) }

  scope :covered,    ->{ where(:"benefit_group_assignments" => {
    :$elemMatch => { :aasm_state => "coverage_selected", :is_active => true }
    })}

  scope :waived,    ->{ where(:"benefit_group_assignments" => {
    :$elemMatch => { :aasm_state => "coverage_waived", :is_active => true }
    })}

  scope :enrolled, -> { any_of([covered.selector, waived.selector]) }


  scope :employee_name, -> (employee_name) { any_of({first_name: /#{employee_name}/i}, {last_name: /#{employee_name}/i}, first_name: /#{employee_name.split[0]}/i, last_name: /#{employee_name.split[1]}/i) }

  scope :sorted,                -> { order(:"census_employee.last_name".asc, :"census_employee.first_name".asc)}
  scope :order_by_last_name,    -> { order(:"census_employee.last_name".asc) }
  scope :order_by_first_name,   -> { order(:"census_employee.first_name".asc) }

  scope :by_employer_profile_id,          ->(employer_profile_id) { where(employer_profile_id: employer_profile_id) }
  scope :non_business_owner,              ->{ where(is_business_owner: false) }
  scope :by_benefit_group_assignment_ids, ->(benefit_group_assignment_ids) { any_in("benefit_group_assignments._id" => benefit_group_assignment_ids) }
  scope :by_benefit_group_ids,            ->(benefit_group_ids) { any_in("benefit_group_assignments.benefit_group_id" => benefit_group_ids) }
  scope :by_ssn,                          ->(ssn) { where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)) }

  scope :matchable, ->(ssn, dob) {
    matched = unscoped.and(encrypted_ssn: CensusMember.encrypt_ssn(ssn), dob: dob, aasm_state: "eligible")
    benefit_group_assignment_ids = matched.flat_map() do |ee|
      ee.published_benefit_group_assignment ? ee.published_benefit_group_assignment.id : []
    end
    matched.by_benefit_group_assignment_ids(benefit_group_assignment_ids)
  }

  scope :unclaimed_matchable, ->(ssn, dob) {
   linked_matched = unscoped.and(encrypted_ssn: CensusMember.encrypt_ssn(ssn), dob: dob, aasm_state: "employee_role_linked")
   unclaimed_person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn), dob: dob).detect{|person| person.employee_roles.length>0 && !person.user }
   unclaimed_person ? linked_matched : unscoped.and(id: {:$exists => false})
  }
  
  def allow_nil_ssn_updates_dependents
    census_dependents.each do |cd|
      if cd.ssn.blank?
        cd.unset(:encrypted_ssn)
      end
    end
  end

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def assign_default_benefit_package
    self.employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED + PlanYear::RENEWING + ['draft']).order_by(:start_on.asc).each do |py|
      if self.benefit_group_assignments.detect{|bg_assign| py.benefit_groups.map(&:id).include?(bg_assign.benefit_group_id) }.blank?
        find_or_build_benefit_group_assignment(py.benefit_groups.first)
      end
    end
  end

  def find_or_build_benefit_group_assignment(benefit_group)
    return unless benefit_group
    return if self.benefit_group_assignments.where(:benefit_group_id => benefit_group.id).present?

    active = false
    if active_benefit_group_assignment.blank?
      active = true
    else
      if PlanYear::PUBLISHED.include?(benefit_group.plan_year.aasm_state)
        self.benefit_group_assignments = self.benefit_group_assignments.map do |bg_assignment|
          bg_assignment.is_active = false
          bg_assignment
        end
      end
    end

    self.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: benefit_group, start_on: benefit_group.start_on, is_active: active)
  end

  def find_or_create_benefit_group_assignment(benefit_group)
    bg_assignments = benefit_group_assignments.where(:benefit_group_id => benefit_group.id).order_by(:'created_at'.desc)
    valid_bg_assignment = bg_assignments.detect{|bg_assign| bg_assign.aasm_state != 'initialized'}
    valid_bg_assignment = bg_assignments.first if valid_bg_assignment.blank?
    if valid_bg_assignment.present?
      valid_bg_assignment.make_active
    else
      add_benefit_group_assignment(benefit_group, benefit_group.plan_year.start_on)
    end
  end

  def add_renew_benefit_group_assignment(new_benefit_group)
    raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)

    benefit_group_assignments.renewing.each do |benefit_group_assignment|
      benefit_group_assignment.destroy
    end

    bga = BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: new_benefit_group.start_on, is_active: false)
    bga.renew_coverage
    benefit_group_assignments << bga
  end

  def add_benefit_group_assignment(new_benefit_group, start_on = TimeKeeper.date_of_record)
    raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)
    reset_active_benefit_group_assignments(new_benefit_group)
    benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: start_on)
  end


  def update_hbx_enrollment_effective_on_by_hired_on
    if employee_role.present? && hired_on != employee_role.hired_on
      employee_role.set(hired_on: hired_on)
      enrollments = employee_role.person.primary_family.active_household.hbx_enrollments.active.open_enrollments rescue []
      enrollments.each do |enrollment|
        if hired_on > enrollment.effective_on
          effective_on = enrollment.benefit_group.effective_on_for(hired_on)
          enrollment.update_current(effective_on: effective_on)
        end
      end
    end
  end

  def new_hire_enrollment_period
    start_on = [hired_on, created_at].max
    end_on = earliest_eligible_date.present? ? [start_on + 30.days, earliest_eligible_date].max : (start_on + 30.days)
    (start_on.beginning_of_day)..(end_on.end_of_day)
  end

  # TODO: eligibility rule different for active and renewal plan years
  def earliest_eligible_date
    benefit_group_assignment = renewal_benefit_group_assignment || active_benefit_group_assignment
    benefit_group_assignment.benefit_group.eligible_on(hired_on) if benefit_group_assignment
  end

  # def first_name=(new_first_name)
  #   write_attribute(:first_name, new_first_name)
  #   set_autocomplete_slug
  # end

  # def last_name=(new_last_name)
  #   write_attribute(:last_name, new_last_name)
  #   set_autocomplete_slug
  # end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(EmployerProfile)
    self.employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    @employer_profile = EmployerProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
  end

  def employee_role=(new_employee_role)
    raise ArgumentError.new("expected EmployeeRole") unless new_employee_role.is_a? EmployeeRole
    return false unless self.may_link_employee_role?

    # Guard against linking employee roles with different employer/identifying information
    if (self.employer_profile_id == new_employee_role.employer_profile._id)
      self.employee_role_id = new_employee_role._id
      self.link_employee_role
      @employee_role = new_employee_role
      self
    else
      message =  "Identifying information mismatch error linking employee role: "\
                 "#{new_employee_role.inspect} "\
                 "with census employee: #{self.inspect}"
      Rails.logger.error { message }
      #raise CensusEmployeeError, message
    end
  end

  def employee_role
    return @employee_role if defined? @employee_role
    @employee_role = EmployeeRole.find(self.employee_role_id) unless self.employee_role_id.blank?
  end

  def add_renew_benefit_group_assignment(new_benefit_group)
    raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)

    benefit_group_assignments.renewing.each do |benefit_group_assignment|
      benefit_group_assignment.destroy
    end

    bga = BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: new_benefit_group.start_on, is_active: false)
    bga.renew_coverage
    benefit_group_assignments << bga
  end

  def add_benefit_group_assignment(new_benefit_group, start_on = TimeKeeper.date_of_record)
    raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)
    reset_active_benefit_group_assignments(new_benefit_group)
    benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: start_on)
  end

  def qle_30_day_eligible?
    is_inactive? && (TimeKeeper.date_of_record - employment_terminated_on).to_i < 30
  end

  def active_benefit_group_assignment
    benefit_group_assignments.detect { |assignment| assignment.is_active? }
  end

  def renewal_benefit_group_assignment
    benefit_group_assignments.order_by(:'updated_at'.desc).detect{ |assignment| assignment.plan_year && assignment.plan_year.is_renewing? }
  end

  def inactive_benefit_group_assignments
    benefit_group_assignments.reject(&:is_active?)
  end

  def published_benefit_group_assignment
    benefit_group_assignments.detect do |benefit_group_assignment|
      benefit_group_assignment.benefit_group.plan_year.employees_are_matchable?
    end
  end

  def add_default_benefit_group_assignment
    if plan_year = (self.employer_profile.plan_years.published_plan_years_by_date(hired_on).first || self.employer_profile.published_plan_year)
      add_benefit_group_assignment(plan_year.benefit_groups.first)
      if self.employer_profile.renewing_plan_year.present?
        add_renew_benefit_group_assignment(self.employer_profile.renewing_plan_year.benefit_groups.first)
      end
    end
  end

  def active_benefit_group
    if active_benefit_group_assignment.present?
      active_benefit_group_assignment.benefit_group
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

  # Initialize a new, refreshed instance for rehires via deep copy
  def replicate_for_rehire
    return nil unless self.employment_terminated?
    new_employee = self.dup
    new_employee.hired_on = nil
    new_employee.employment_terminated_on = nil
    new_employee.employee_role_id = nil
    new_employee.benefit_group_assignments = []
    new_employee.aasm_state = :eligible
    self.rehire_employee_role

    # new_employee.census_dependents = self.census_dependents unless self.census_dependents.blank?
    new_employee
  end

  def is_business_owner?
    is_business_owner
  end

  def is_covered_or_waived?
    ["coverage_selected", "coverage_waived"].include?(active_benefit_group_assignment.aasm_state)
  end

  def email_address
    return nil unless email.present?
    email.address
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

  def terminate_employment!(employment_terminated_on)

    if employment_terminated_on < TimeKeeper.date_of_record

      if may_terminate_employee_role?

        unless employee_termination_pending?

          self.employment_terminated_on = employment_terminated_on
          self.coverage_terminated_on = earliest_coverage_termination_on(employment_terminated_on)

          census_employee_hbx_enrollment = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(active_benefit_group_assignment)
          census_employee_hbx_enrollment.map { |e| self.employment_terminated_on < e.effective_on ? e.cancel_coverage!(self.employment_terminated_on) : e.schedule_coverage_termination!(self.coverage_terminated_on) }

          census_employee_hbx_enrollment = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(renewal_benefit_group_assignment)
          census_employee_hbx_enrollment.map { |e| self.employment_terminated_on < e.effective_on ? e.cancel_coverage!(self.employment_terminated_on) : e.schedule_coverage_termination!(self.coverage_terminated_on)  }

        end
        terminate_employee_role!
      else
        message = "Error terminating employment: unable to terminate employee role for: #{self.full_name}"
        Rails.logger.error { message }
        raise CensusEmployeeError, message
      end
    else # Schedule Future Terminations as employment_terminated_on is in the future

      self.employment_terminated_on = employment_terminated_on
      self.coverage_terminated_on = earliest_coverage_termination_on(employment_terminated_on)

      if may_schedule_employee_termination? || employee_termination_pending?
          schedule_employee_termination!
          census_employee_hbx_enrollment = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(active_benefit_group_assignment)
          census_employee_hbx_enrollment.map { |e| self.employment_terminated_on < e.effective_on ? e.cancel_coverage!(self.employment_terminated_on) : e.schedule_coverage_termination!(self.coverage_terminated_on) }

          census_employee_hbx_enrollment = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(renewal_benefit_group_assignment)
          census_employee_hbx_enrollment.map { |e| self.employment_terminated_on < e.effective_on ? e.cancel_coverage!(self.employment_terminated_on) : e.schedule_coverage_termination!(self.coverage_terminated_on) }

      end
    end

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

    # if current_user.has_hbx_staff_role?
    # end

    [employment_based_date, submitted_based_date].max
  end

  def is_active?
    EMPLOYMENT_ACTIVE_STATES.include?(aasm_state)
  end

  def is_inactive?
    EMPLOYMENT_TERMINATED_STATES.include?(aasm_state)
  end

  def employee_relationship
    "employee"
  end

  def build_from_params(census_employee_params, benefit_group_id)
    self.attributes = census_employee_params

    if benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(benefit_group_id))
      new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, self)
      self.benefit_group_assignments = new_benefit_group_assignment.to_a
    end
  end

  def send_invite!
    if has_benefit_group_assignment?
      plan_year = active_benefit_group_assignment.benefit_group.plan_year
      if plan_year.employees_are_matchable?
        Invitation.invite_employee!(self)
        return true
      end
    end
    false
  end

  def construct_employee_role_for_match_person
    employee_relationship = Forms::EmployeeCandidate.new({first_name: first_name,
                                                          last_name: last_name,
                                                          ssn: ssn,
                                                          dob: dob.strftime("%Y-%m-%d")})
    person = employee_relationship.match_person if employee_relationship.present?
    return false if person.blank? || (person.present? && 
                                      person.has_active_employee_role_for_census_employee?(self))
    Factories::EnrollmentFactory.build_employee_role(person, nil, employer_profile, self, hired_on)
    return true
  end

  def newhire_enrollment_eligible?
    active_benefit_group_assignment.present? && active_benefit_group_assignment.initialized?
  end

  def has_active_health_coverage?(plan_year)
    benefit_group_ids = plan_year.benefit_groups.map(&:id)

    bg_assignment = active_benefit_group_assignment if benefit_group_ids.include?(active_benefit_group_assignment.try(:benefit_group_id))
    bg_assignment = renewal_benefit_group_assignment if benefit_group_ids.include?(renewal_benefit_group_assignment.try(:benefit_group_id))

    bg_assignment.present? && HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(bg_assignment).present?
  end

  class << self

    def advance_day(new_date)
      CensusEmployee.terminate_scheduled_census_employees
    end

    def terminate_scheduled_census_employees(as_of_date = TimeKeeper.date_of_record)
      census_employees_for_termination = CensusEmployee.where(:aasm_state => "employee_termination_pending", :employment_terminated_on.lt => as_of_date)
      census_employees_for_termination.each do |census_employee|
        census_employee.terminate_employment(census_employee.employment_terminated_on)
      end
    end

    def find_all_by_employer_profile(employer_profile)
      unscoped.where(employer_profile_id: employer_profile._id).order_name_asc
    end

    alias_method :find_by_employer_profile, :find_all_by_employer_profile

    def find_all_by_employee_role(employee_role)
      unscoped.where(employee_role_id: employee_role._id)
    end

    def find_all_by_benefit_group(benefit_group)
      unscoped.where("benefit_group_assignments.benefit_group_id" => benefit_group._id)
    end

    def find_all_terminated(employer_profiles: [], date_range: (TimeKeeper.date_of_record..TimeKeeper.date_of_record))

      if employer_profiles.size > 0
        employer_profile_ids = employer_profiles.map(&:_id)
        query = unscoped.terminated.any_in(employer_profile_id: employer_profile_ids).
                                    where(
                                      :employment_terminated_on.gte => date_range.first,
                                      :employment_terminated_on.lte => date_range.last
                                    )
      else
        query = unscoped.terminated.where(
                                    :employment_terminated_on.gte => date_range.first,
                                    :employment_terminated_on.lte => date_range.last
                                  )
      end
      query.to_a
    end

    # Update CensusEmployee records when Person record is updated. (SSN / DOB change)
    def update_census_employee_records(person, current_user)
      person.employee_roles.each do |employee_role|
        ce = employee_role.census_employee
        if current_user.has_hbx_staff_role? && ce.present?
          ce.ssn = person.ssn
          ce.dob = person.dob
          ce.save!(validate: false)
        end
      end
    end 

  end

  aasm do
    state :eligible, initial: true
    state :employee_role_linked
    state :employee_termination_pending
    state :employment_terminated
    state :rehired

    event :rehire_employee_role, :after => :record_transition do
      transitions from: [:employment_terminated], to: :rehired
    end

    event :link_employee_role, :after => :record_transition do
      transitions from: :eligible, to: :employee_role_linked, :guard => :has_benefit_group_assignment?
    end

    event :delink_employee_role, :guard => :has_no_hbx_enrollments?, :after => :record_transition do
      transitions from: :employee_role_linked, to: :eligible, :after => :clear_employee_role
    end

    event :schedule_employee_termination, :after => :record_transition do
      transitions from: [:employee_termination_pending, :eligible, :employee_role_linked], to: :employee_termination_pending
    end

    event :terminate_employee_role, :after => :record_transition do
      transitions from: [:eligible, :employee_role_linked, :employee_termination_pending], to: :employment_terminated
    end
  end

  def self.roster_import_fallback_match(f_name, l_name, dob, bg_id)
    fname_exp = Regexp.compile(Regexp.escape(f_name), true)
    lname_exp = Regexp.compile(Regexp.escape(l_name), true)
    self.where({
      first_name: fname_exp,
      last_name: lname_exp,
      dob: dob
    }).any_in("benefit_group_assignments.benefit_group_id" => [bg_id])
  end

  def self.to_csv
    attributes = %w{employee_name dob hired status renewal_benefit_package benefit_package enrollment_status termination_date}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |census_employee|
        data = [
          "#{census_employee.first_name} #{census_employee.middle_name} #{census_employee.last_name} ",
          census_employee.dob,
          census_employee.hired_on,
          census_employee.aasm_state.humanize.downcase,
          census_employee.renewal_benefit_group_assignment.try(:benefit_group).try(:title)
        ]

        if active_assignment = census_employee.active_benefit_group_assignment
          data += [
            active_assignment.benefit_group.title,
            "dental: #{ d = active_assignment.try(:hbx_enrollments).detect{|enrollment| enrollment.coverage_kind == 'dental'}.try(:aasm_state).try(:humanize).try(:downcase)} health: #{ active_assignment.try(:hbx_enrollments).detect{|enrollment| enrollment.coverage_kind == 'health'}.try(:aasm_state).try(:humanize).try(:downcase)}"
          ]
        else
          data += [nil, nil]
        end
        csv << (data + [census_employee.coverage_terminated_on])
      end
    end
  end

  def enrollments_for_display
    enrollments = []

    coverages_selected = lambda do |benefit_group_assignment|
      return [] if benefit_group_assignment.blank?
      coverages = benefit_group_assignment.hbx_enrollments.reject{|e| e.external_enrollment}
      [coverages.detect{|c| c.coverage_kind == 'health'}, coverages.detect{|c| c.coverage_kind == 'dental'}]
    end

    enrollments += coverages_selected.call(active_benefit_group_assignment)
    enrollments += coverages_selected.call(renewal_benefit_group_assignment)
    enrollments.compact.uniq
  end
  
  private

  def reset_active_benefit_group_assignments(new_benefit_group)
    benefit_group_assignments.select { |assignment| assignment.is_active? }.each do |benefit_group_assignment|
      benefit_group_assignment.end_on = [new_benefit_group.start_on - 1.day, benefit_group_assignment.start_on].max
      benefit_group_assignment.update_attributes(is_active: false)
    end
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

  def set_autocomplete_slug
    return unless (first_name.present? && last_name.present?)
    @autocomplete_slug = first_name.concat(" #{last_name}")
  end

  def has_no_hbx_enrollments?
    return true if employee_role.blank?
    !benefit_group_assignments.detect { |bga| bga.hbx_enrollment.present? }
  end

  def check_employment_terminated_on
    if employment_terminated_on && employment_terminated_on <= hired_on
      errors.add(:employment_terminated_on, "can't occur before hiring date")
    end

    if !self.employment_terminated? && !self.rehired?
      if employment_terminated_on && employment_terminated_on <= TimeKeeper.date_of_record - 60.days
        errors.add(:employment_terminated_on, "Employee termination must be within the past 60 days")
      end
    end
  end


  def no_duplicate_census_dependent_ssns
    dependents_ssn = census_dependents.map(&:ssn).select(&:present?)
    if dependents_ssn.uniq.length != dependents_ssn.length ||
       dependents_ssn.any?{|dep_ssn| dep_ssn==self.ssn}
      errors.add(:base, "SSN's must be unique for each dependent and subscriber")
    end
  end

  def active_census_employee_is_unique
    potential_dups = CensusEmployee.by_ssn(ssn).by_employer_profile_id(employer_profile_id).active
    if potential_dups.detect { |dup| dup.id != self.id  }
      message = "Employee with this identifying information is already active. "\
                "Update or terminate the active record before adding another."
      errors.add(:base, message)
    end
  end

  def check_census_dependents_relationship
    return true if census_dependents.blank?

    relationships = census_dependents.map(&:employee_relationship)
    if relationships.count{|rs| rs=='spouse' || rs=='domestic_partner'} > 1
      errors.add(:census_dependents, "can't have more than one spouse or domestic partner.")
    end
  end

  # SSN and DOB values may be edited only in pre-linked status
  def allow_id_info_changes_only_in_eligible_state
    if (ssn_changed? || dob_changed?) && aasm_state != "eligible"
      message = "An employee's identifying information may change only when in 'eligible' status. "
      errors.add(:base, message)
    end
  end

  def check_hired_on_before_dob
    if hired_on && dob && hired_on <= dob
      errors.add(:hired_on, "date can't be before  date of birth.")
    end
  end

  def may_terminate_benefit_group_assignment_coverage?
    if active_benefit_group_assignment.present? && active_benefit_group_assignment.may_terminate_coverage?
      return true
    else
      return false
    end
  end
  
  def has_benefit_group_assignment?
    (active_benefit_group_assignment.present? && (PlanYear::PUBLISHED).include?(active_benefit_group_assignment.benefit_group.plan_year.aasm_state)) ||
    (renewal_benefit_group_assignment.present? && (PlanYear::RENEWING_PUBLISHED_STATE).include?(renewal_benefit_group_assignment.benefit_group.plan_year.aasm_state))
  end

  def clear_employee_role
    # employee_role.
    self.employee_role_id = nil
    unset("employee_role_id")
    self.benefit_group_assignments = []
    @employee_role = nil
  end
end

class CensusEmployeeError < StandardError; end
