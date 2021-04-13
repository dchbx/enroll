require 'services/checkbook_services/plan_comparision'

# An instance of the CensusEmployee is an employee that belongs to a Benefit Sponsor.
# It is the primary way for us to refer to the employee of an employer.
# This is different from a person, though it references the person through the employee_role model.
# Dependents of the census employee (CensusDependents) are embedded in the CensusEmployee.
# Embeded document BenefitGroupAssignment is the model responsible for connecting the CensusEmployee with the approriate coverage.
#                            ,------------------.                        ,------.
#                            |BenefitSponsorship|                        |person|
#                            |------------------|                        |------|
#                            |------------------|                        |------|
#                            `------------------'                        `------'
#                              |                |                             |
#                              |                |                             |
#  ,------------------------------------.       |                             |
#  |CensusEmployee                      |  ,---------------------.   ,------------.
#  |------------------------------------|  |BenefitCoveragePeriod|   |EmployeeRole|
#  |benefit_sponsors_employer_profile_id|  |---------------------|   |------------|
#  |employee_role_id                    |  |---------------------|   |------------|
#  |------------------------------------|  `---------------------'   `------------'
#  `------------------------------------'       |                            |
#                 |                   |_________|____________________________|
#                 |                             |
#  ,----------------------.     ,--------------.
#  |BenefitGroupAssignment|     |BenefitPackage|
#  |----------------------|     |--------------|
#  |----------------------|-----|--------------|
#  `----------------------'     `--------------'

class CensusEmployee < CensusMember
  include AASM
  include Sortable
  include Searchable
  # include Validations::EmployeeInfo
  include Autocomplete
  include Acapi::Notifiers
  include Config::AcaModelConcern
  include ::Eligibility::CensusEmployee
  include ::Eligibility::EmployeeBenefitPackages
  include BenefitSponsors::Concerns::Observable
  include Insured::FamiliesHelper
  include BenefitSponsors::ModelEvents::CensusEmployee
  include Ssn

  require 'roo'

  # @!group AASM state groupings
  EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
  EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated cobra_terminated rehired)
  EMPLOYMENT_ACTIVE_ONLY = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked)
  NEWLY_DESIGNATED_STATES = %w(newly_designated_eligible newly_designated_linked)
  LINKED_STATES = %w(employee_role_linked newly_designated_linked cobra_linked)
  ELIGIBLE_STATES = %w(eligible newly_designated_eligible cobra_eligible employee_termination_pending cobra_termination_pending)
  COBRA_STATES = %w(cobra_eligible cobra_linked cobra_terminated cobra_termination_pending)
  PENDING_STATES = %w(employee_termination_pending cobra_termination_pending)
  ENROLL_STATUS_STATES = %w(enroll waive will_not_participate)

  EMPLOYEE_TERMINATED_EVENT_NAME = "acapi.info.events.census_employee.terminated"
  EMPLOYEE_COBRA_TERMINATED_EVENT_NAME = "acapi.info.events.census_employee.cobra_terminated"
  # @!endgroup

  CONFIRMATION_EFFECTIVE_DATE_TYPES = ['cobra', 'rehire', 'terminate'].freeze

  field :is_business_owner, type: Boolean, default: false
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :coverage_terminated_on, type: Date
  field :aasm_state, type: String
  field :expected_selection, type: String, default: "enroll"
  field :no_ssn_allowed, type: Boolean, default: false
  field :age_off_excluded, type: Boolean, default: false

  # Employer for this employee
  # @return [EmployerProfile]
  field :employer_profile_id, type: BSON::ObjectId
  # Employer for this employee
  # @return [BenefitSponsors::Organizations::AcaShopCcaEmployerProfile]
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

  accepts_nested_attributes_for :census_dependents, :benefit_group_assignments

  validates_presence_of :dob, :hired_on, :is_business_owner
  validates_presence_of :ssn, :if => Proc.new { |m| !m.no_ssn_allowed }
  validates_presence_of :employer_profile_id, :if => Proc.new { |m| m.benefit_sponsors_employer_profile_id.blank? }
  validates_presence_of :benefit_sponsors_employer_profile_id, :if => Proc.new { |m| m.employer_profile_id.blank? }
  validate :check_employment_terminated_on
  validate :active_census_employee_is_unique
  validate :allow_id_info_changes_only_in_eligible_state
  validate :check_census_dependents_relationship
  validate :no_duplicate_census_dependent_ssns
  validate :check_cobra_begin_date
  validate :check_hired_on_before_dob
  validates :expected_selection,
    inclusion: {in: ENROLL_STATUS_STATES, message: "%{value} is not a valid  expected selection" }
  validate :validate_unique_identifier
  after_update :update_hbx_enrollment_effective_on_by_hired_on
  after_save :assign_default_benefit_package
  after_save :assign_benefit_packages
  after_save :notify_on_save

  before_save :allow_nil_ssn_updates_dependents
  after_save :construct_employee_role

  add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_census_employee_events]

  index({aasm_state: 1})
  index({last_name: 1})
  index({dob: 1})

  index({encrypted_ssn: 1, dob: 1, aasm_state: 1})
  index({employee_role_id: 1}, {sparse: true})
  index({employer_profile_id: 1, encrypted_ssn: 1, aasm_state: 1})
  index({employer_profile_id: 1, last_name: 1, first_name: 1, hired_on: -1 })
  index({employer_profile_id: 1, hired_on: 1, last_name: 1, first_name: 1 })
  index({employer_profile_id: 1, is_business_owner: 1})

  index({"benefit_sponsorship_id" => 1})
  index({"benefit_sponsors_employer_profile_id" => 1})
  index({"benefit_group_assignments._id" => 1})
  index({"benefit_group_assignments.benefit_group_id" => 1})
  index({"benefit_group_assignments.benefit_package_id" => 1})
  index(
    {
      "benefit_group_assignments.benefit_package_id" => 1,
      "benefit_group_assignments.start_on" => 1
    },
    {
      name: "benefit_group_assignments_renewal_search_index"
    }
  )

  scope :active,            ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
  scope :terminated,        ->{ any_in(aasm_state: EMPLOYMENT_TERMINATED_STATES) }
  scope :non_terminated,    ->{ where(:aasm_state.nin => EMPLOYMENT_TERMINATED_STATES) }
  scope :non_term_and_pending, ->{ where(:aasm_state.nin => (EMPLOYMENT_TERMINATED_STATES + PENDING_STATES)) }
  scope :newly_designated,  ->{ any_in(aasm_state: NEWLY_DESIGNATED_STATES) }
  scope :linked,            ->{ any_in(aasm_state: LINKED_STATES) }
  scope :eligible,          ->{ any_in(aasm_state: ELIGIBLE_STATES) }
  scope :without_cobra,     ->{ not_in(aasm_state: COBRA_STATES) }
  scope :by_cobra,          ->{ any_in(aasm_state: COBRA_STATES) }
  scope :pending,           ->{ any_in(aasm_state: PENDING_STATES) }
  scope :active_alone,      ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_ONLY) }

  # scope :emplyee_profiles_active_cobra,        ->{ where(aasm_state: "eligible") }
  scope :employee_profiles_terminated,         ->{ where(aasm_state: "employment_terminated")}
  scope :eligible_without_term_pending, ->{ any_in(aasm_state: (ELIGIBLE_STATES - PENDING_STATES)) }

  scope :by_benefit_package_and_assignment_on_or_later, lambda { |benefit_package, effective_on|
    where(
      :benefit_group_assignments => {
        :$elemMatch => {
          :start_on.gte => effective_on,
          :benefit_package_id => benefit_package.id,
          "$or" => [
            {"end_on" => nil},
            {"end_on" => {"$gt" => effective_on}}
          ]
        }
      }
    )
  }

  #TODO - need to add fix for multiple plan years
  # AASM_STATE deprecated for benefit group assignment
  # scope :enrolled,    ->{ where("benefit_group_assignments.aasm_state" => ["coverage_selected", "coverage_waived"]) }
  # scope :covered,     ->{ where( "benefit_group_assignments.aasm_state" => "coverage_selected" ) }
  # scope :waived,      ->{ where( "benefit_group_assignments.aasm_state" => "coverage_waived" ) }

  # TODO: Need to refactor others like this to compensate for no aasm state
  scope :covered, lambda {
    ces_with_covered_start_ons_and_enrollments = where(
      :benefit_group_assignments => {
        :$elemMatch => { :hbx_enrollment_id.nin => [nil], :start_on.lte => TimeKeeper.date_of_record }
      }
    )
    covered_ce_ids = ces_with_covered_start_ons_and_enrollments.select do |ce|
      if [ce.active_benefit_group_assignment, ce.active_benefit_group_assignment&.hbx_enrollment_id].all?
        HbxEnrollment::ENROLLED_STATUSES.include?(ce.active_benefit_group_assignment.hbx_enrollment.aasm_state)
      elsif ce.employee_role
        HbxEnrollment.where(employee_role_id: ce.employee_role.id, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES).present?
      end
    end.map(&:id)
    where(:_id.in => covered_ce_ids)
  }

  scope :waived, lambda {
    ces_with_hbx_enrollments = where(
      :benefit_group_assignments => {
        :$elemMatch => { :hbx_enrollment_id.nin => [nil]}
      }
    )
    enrolled_ce_ids = ces_with_hbx_enrollments.select do |ce|
      if [ce.active_benefit_group_assignment, ce.active_benefit_group_assignment&.hbx_enrollment_id].all?
        HbxEnrollment::WAIVED_STATUSES.include?(ce.active_benefit_group_assignment.hbx_enrollment.aasm_state)
      elsif ce.employee_role
        HbxEnrollment.where(employee_role_id: ce.employee_role.id, :aasm_state.in => HbxEnrollment::WAIVED_STATUSES).present?
      end
    end.map(&:id)
    where(:_id.in => enrolled_ce_ids)
  }

  scope :covered_progressbar, lambda {
    where(
      :benefit_group_assignments => {
        :$elemMatch => { :aasm_state.in => ["coverage_selected","coverage_renewing"]  }
      }
    )
  }

  scope :enrolled, -> { any_of([covered.selector, waived.selector]) }


  scope :employee_name, -> (employee_name) { any_of({first_name: /#{employee_name}/i}, {last_name: /#{employee_name}/i}, first_name: /#{employee_name.split[0]}/i, last_name: /#{employee_name.split[1]}/i) }

  scope :sorted,                -> { order(:"census_employee.last_name".asc, :"census_employee.first_name".asc)}
  scope :order_by_last_name,    -> { order(:"census_employee.last_name".asc) }
  scope :order_by_first_name,   -> { order(:"census_employee.first_name".asc) }

  scope :by_old_employer_profile_id,          ->(employer_profile_id) { where(employer_profile_id: employer_profile_id) }
  scope :by_benefit_sponsor_employer_profile_id,          ->(benefit_sponsors_employer_profile_id) { where(benefit_sponsors_employer_profile_id: benefit_sponsors_employer_profile_id) }
  scope :non_business_owner,              ->{ where(is_business_owner: false) }
  scope :by_benefit_group_assignment_ids, ->(benefit_group_assignment_ids) { any_in("benefit_group_assignments._id" => benefit_group_assignment_ids) }
  scope :by_benefit_group_ids,            ->(benefit_group_ids) { any_in("benefit_group_assignments.benefit_group_id" => benefit_group_ids) }
  scope :by_ssn,                          ->(ssn) { where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).and(:encrypted_ssn.nin => ["", nil]) }

  scope :by_benefit_package_and_assignment_on, lambda { |benefit_package, effective_on|
    where(
      :benefit_group_assignments => {
        :$elemMatch =>
        {
          :benefit_package_id => benefit_package.id,
          :start_on => effective_on
        }
      }
    )
  }

  index(
    {'benefit_group_assignments.benefit_package_id' => 1,
     'benefit_group_assignments.effective_on' => 1,
     'benefit_group_assignments.is_active' => 1},
    {name: 'benefit_package_by_benefit_group_assignments_start_on_index'}
  )

  index(
    {
      "benefit_group_assignments.benefit_package_id" => 1,
      "benefit_group_assignments.start_on" => 1,
      "benefit_group_assignments.end_on" => 1,
      "employment_terminated_on" => 1
    },
   {name: "benefit_group_assignments_predecessor_renewal_index"})

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

  scope :benefit_application_assigned,     ->(benefit_application) { where(:"benefit_group_assignments.benefit_package_id".in => benefit_application.benefit_packages.pluck(:_id)) }
  scope :benefit_application_unassigned,   ->(benefit_application) { where(:"benefit_group_assignments.benefit_package_id".nin => benefit_application.benefit_packages.pluck(:_id)) }

  scope :matchable, ->(ssn, dob) {
    matched = unscoped.and(encrypted_ssn: CensusMember.encrypt_ssn(ssn), dob: dob, aasm_state: {"$in": ELIGIBLE_STATES })
    benefit_group_assignment_ids = matched.flat_map() do |ee|
      ee.published_benefit_group_assignment ? ee.published_benefit_group_assignment.id : []
    end
    matched.by_benefit_group_assignment_ids(benefit_group_assignment_ids)
  }

  scope :unclaimed_matchable, ->(ssn, dob) {
   linked_matched = unscoped.and(encrypted_ssn: CensusMember.encrypt_ssn(ssn), dob: dob, aasm_state: {"$in": LINKED_STATES})
   unclaimed_person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn), dob: dob).detect{|person| person.employee_roles.length>0 && !person.user }
   unclaimed_person ? linked_matched : unscoped.and(id: {:$exists => false})
  }

  scope :matchable_by_dob_lname_fname, ->(dob, first_name, last_name) {
    matched = unscoped.and(dob: dob, first_name: first_name, last_name: last_name, aasm_state: {"$in": ELIGIBLE_STATES })
    benefit_group_assignment_ids = matched.flat_map() do |ee|
      ee.published_benefit_group_assignment ? ee.published_benefit_group_assignment.id : []
    end
    matched.by_benefit_group_assignment_ids(benefit_group_assignment_ids)
  }

  scope :census_employees_active_on, -> (date) {
    where(
      "$or" => [
        {"employment_terminated_on" => nil},
        {"employment_terminated_on" => {"$gte" => date}}
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

  # This initializes a new CensusEmploye with the given +args+, the method
  # has been overriden to write the attribute +:employee_relationship+ to +"self"+
  # @param args [Hash]
  # @return [CensusEmployee]
  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def is_no_ssn_allowed?
    employer_profile.active_benefit_sponsorship.is_no_ssn_enabled
  end

  # Retrieves the benefit_group_assignment for a given +benefit_package+ with
  # a specific +effecitive_on+ date. If no date is specified +TimeKeeper.date_of_record+ is used.
  # @param benefit_package [BenefitPackage]
  # @param effective_on [Date]
  # @return [BenefitGroupAssignment]
  def benefit_package_assignment_on(date = TimeKeeper.date_of_record)
    BenefitGroupAssignment.on_date(self, date)
  end

  def assign_benefit_package(new_benefit_package, start_on = TimeKeeper.date_of_record)
    unless new_benefit_package.cover?(start_on)
      Rails.logger.error { "start_on date (#{start_on}) is not within the benefit package (#{new_benefit_package.id}) effective period" }
      return
    end

    if benefit_group_assignments.empty?
      create_benefit_package_assignment(new_benefit_package, start_on)
    else
      update_benefit_package_assignment(new_benefit_package, start_on)
    end
  end

  def create_benefit_package_assignment(new_benefit_package, start_on)
    new_assignment = benefit_group_assignments.build(start_on: start_on, end_on: new_benefit_package.end_on, benefit_package: new_benefit_package)

    if new_assignment.save
      new_assignment
    else
      Rails.logger.error { "Failed to create new_assignment for census employee (#{self.id}) with benefit package (#{new_benefit_package.id}) with start_on: #{start_on} due to #{assignment.errors.inspect}" }
    end
  end

  def update_benefit_package_assignment(new_benefit_package, start_on)
    current_assignment = benefit_package_assignment_on(start_on)

    if current_assignment.blank?
      create_benefit_package_assignment(new_benefit_package, start_on)
    elsif current_assignment.is_belong_to?(new_benefit_package)
      current_assignment
    else
      replace_package_assignment(current_assignment, new_benefit_package, start_on)
    end
  end

  def replace_package_assignment(assignment, new_benefit_package, start_on)
    assignment.end_date = start_on.prev_day

    if assignment.save
      create_benefit_package_assignment(new_benefit_package, start_on)
    else
      Rails.logger.error { "Failed to save package assignment (#{assignment.id}) for census employee (#{self.id}) due to #{assignment.errors.inspect}" }
    end
  end

  def terminate_benefit_package_assignment(benefit_package, terminated_on)
    package_assignments = benefit_group_assignments.by_benefit_package(benefit_package).by_date(terminated_on).reject(&:canceled?)
    package_assignments.each do |assignment|
      assignment.end_on = terminated_on
      Rails.logger.error { "Failed to terminate package assignment (#{assignment.id}) with termination date #{terminated_on} for census employee (#{self.id}) due to #{assignment.errors.inspect}" } unless assignment.save
    end
  end

  def cancel_benefit_package_assignment(benefit_package)
    package_assignments = benefit_group_assignments.by_benefit_package(benefit_package).reject(&:canceled?)
    package_assignments.each do |assignment|
      assignment.end_on = assignment.start_on
      Rails.logger.error { "Failed to cancel package assignment (#{assignment.id}) for census employee (#{self.id}) due to #{assignment.errors.inspect}" } unless assignment.save
    end
  end

  # CensusEmployee.with_session do |session|
  #   session.start_transaction
  #   existing_assignment.save! if existing_assignment.present?
  #   new_assignment.save!
  #   begin
  #     session.commit_transaction
  #   rescue Mongo::Error => e
  #     Rails.logger.error { "Failed to assign benefit package (#{benefit_package.id}) with start_on: #{start_on} due to #{e.inspect}" }
  #     raise
  #   end
  # end

  def benefit_group_assignment_for(benefit_package, effective_on = TimeKeeper.date_of_record)
    benefit_group_assignments.by_benefit_package_and_assignment_on(benefit_package, effective_on).first
  end

  # Returns the family associated with the associated +employee_role+'s +person+.
  # @return [Family]
  def family
    return nil if employee_role.blank?
    person_rec = employee_role.person
    person_rec.primary_family
  end

  # Evalutes whether the +CensusEmployee+ is linked or not by checking +aasm_states+.
  # @return [Boolean]
  def is_linked?
    LINKED_STATES.include?(aasm_state)
  end

  # Evalutes whether the +CensusEmployee+ is eligible or not by checking +aasm_states+.
  # @return [Boolean]
  def is_eligible?
    ELIGIBLE_STATES.include?(aasm_state)
  end

  # Loops though +census_dependents+ and if their SSN is blank nils the +encrypted_ssn+ field.
  def allow_nil_ssn_updates_dependents
    census_dependents.each do |cd|
      if cd.ssn.blank?
        cd.unset(:encrypted_ssn)
      end
    end
  end

  # TODO: Need to figure out wha the criteria for "deactivate" here is.
  # Maybe can delete this, doesn't seem to be called anywhere.
  # Deactivates benefit group assignments for the given +benefit_package_ids+.
  # @param benefit_package_ids [Array<Integer>]
  # def deactive_benefit_group_assignments(benefit_package_ids)
  #  assignments = benefit_group_assignments.where(:benefit_package_id.in => benefit_package_ids)
  #  assignments.each do |assignment|
  #    if assignment.may_delink_coverage?
  #      assignment.delink_coverage!
  #      assignment.update_attribute(:is_active, false)
  #    end
  #  end
  # end

  # Assigns census employee to +benefit_package+ with +start_on+ being set to +assignment_on+.
  # @param benefit_package [BenefitPackage]
  # @param assignment_on [Date]
  # @return [BenefitGroupAssignment]
  def assign_to_benefit_package(benefit_package, assignment_on)
    return if benefit_package.blank?

    benefit_group_assignments.create!(
      start_on: assignment_on,
      end_on:   benefit_package.effective_period.max,
      benefit_package: benefit_package,
    )
  end

  # Finds benefit group assignments for a given +benefit_package+.
  # @param benefit_package [BenefitPackage]
  # @return [Array<BenefitGroupAssignment>]
  def benefit_package_assignment_for(benefit_package)
    benefit_group_assignments.effective_on(benefit_package.effective_period.min).detect{ |assignment|
      assignment.benefit_package_id == benefit_package.id
    }
  end

  # def benefit_package_assignment_on(effective_date)
  #   benefit_group_assignments.effective_on(effective_date).active.first
  # end

  def update_hbx_enrollment_effective_on_by_hired_on
    if employee_role.present? && hired_on != employee_role.hired_on
      employee_role.set(hired_on: hired_on)
      enrollments = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.open_enrollments rescue []
      enrollments.each do |enrollment|
        if hired_on > enrollment.effective_on
          effective_on = enrollment.benefit_group.effective_on_for(hired_on)
          enrollment.update_attributes!(effective_on: effective_on)
        end
      end
    end
  end

  def suggested_cobra_effective_date
    return nil if self.employment_terminated_on.nil?
    self.employment_terminated_on.next_month.beginning_of_month
  end

  def is_case_old?(profile=nil)
    if profile.present?
      profile.is_a?(EmployerProfile)
    else
      benefit_sponsors_employer_profile_id.blank?
    end
  end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.class.to_s.match(/EmployerProfile/)
    if is_case_old?(new_employer_profile)
      self.employer_profile_id = new_employer_profile._id
    else
      self.benefit_sponsors_employer_profile_id = new_employer_profile._id
    end
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    return @employer_profile = EmployerProfile.find(self.employer_profile_id) if (self.employer_profile_id.present? && self.benefit_sponsors_employer_profile_id.blank?)
    return nil if self.benefit_sponsorship.blank? # Need this for is_case_old?
    @employer_profile = self.benefit_sponsorship.organization.employer_profile
  end

  # This performs employee summary count for waived and enrolled in the latest plan year
  def perform_employer_plan_year_count
    if plan_year = self.employer_profile.latest_plan_year
      plan_year.enrolled_summary = plan_year.total_enrolled_count
      plan_year.waived_summary = plan_year.waived_count
      plan_year.save!
    end
  end

  def employee_record_claimed?(new_employee_role = nil)
    if new_employee_role.present?
      new_employee_role.person.user.present?
    else
      return false unless employee_role
      employee_role.person.user.present?
    end
  end

  def employee_role=(new_employee_role)
    raise ArgumentError.new("expected EmployeeRole") unless new_employee_role.is_a? EmployeeRole
    return false unless self.may_link_employee_role?
    # Guard against linking employee roles with different employer/identifying information
    slug = is_case_old? && self.employer_profile_id == new_employee_role.employer_profile_id
    if (self.benefit_sponsors_employer_profile_id == new_employee_role.benefit_sponsors_employer_profile_id) || slug
      self.employee_role_id = new_employee_role._id
      @employee_role = new_employee_role
      self.link_employee_role! if employee_record_claimed?(new_employee_role)
    else
      message =  "Identifying information mismatch error linking employee role: "\
                 "#{new_employee_role.inspect} "\
                 "with census employee: #{self.inspect}"
      Rails.logger.error { message }
      #raise CensusEmployeeError, message
    end
  end

  def employee_role
    return nil if self.employee_role_id.nil?
    return @employee_role if @employee_role
    @employee_role = EmployeeRole.find(self.employee_role_id)
  end

  def newly_designated?
    newly_designated_eligible? || newly_designated_linked?
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

  def active_benefit_group_assignment(coverage_date = TimeKeeper.date_of_record)
    benefit_package_assignment_on(coverage_date) || benefit_group_assignments.detect(&:is_active)
  end

  # Pass in active coverage_date to get the renewal benefit group assignment
  def renewal_benefit_group_assignment(coverage_date = nil)
    active_assignment = coverage_date ? active_benefit_group_assignment(coverage_date) : active_benefit_group_assignment
    return unless active_assignment&.benefit_package.present?

    renewal_begin_date = active_assignment.benefit_package.end_on.next_day
    renewal_assignment = benefit_package_assignment_on(renewal_begin_date)
    return nil if renewal_assignment&.benefit_package&.benefit_application == benefit_sponsorship&.off_cycle_benefit_application

    renewal_assignment
  end

  def off_cycle_benefit_group_assignment
    off_cycle_app = benefit_sponsorship&.off_cycle_benefit_application
    return if active_benefit_group_assignment.nil? || off_cycle_app.nil?

    benefit_package_ids = off_cycle_app.benefit_packages.map(&:id)
    benefit_group_assignments.detect { |benefit_group_assignment| benefit_package_ids.include?(benefit_group_assignment.benefit_package.id) && benefit_group_assignment.is_active?(off_cycle_app.start_on) }
  end

  # DEPRECATE IF POSSIBLE
  def published_benefit_group_assignment
    assignments = benefit_group_assignments.select do |benefit_group_assignment|
      benefit_group_assignment.benefit_group.is_active && benefit_group_assignment.benefit_group.plan_year.employees_are_matchable?
    end

    assignments.detect(&:is_active) || assignments.sort_by(&:created_at).reverse.first
  end

  def active_benefit_package(coverage_date = TimeKeeper.date_of_record)
    return unless (active_assignment = active_benefit_group_assignment(coverage_date))

    active_assignment.benefit_package if active_assignment.benefit_package.plan_year.employees_are_matchable?
  end

  alias_method :active_benefit_group, :active_benefit_package

  def published_benefit_group
    published_benefit_group_assignment.benefit_group if published_benefit_group_assignment
  end

  # Pass in current coverage_date to get the renewal benefit package
  def renewal_published_benefit_package(coverage_date = nil)
    return unless (renewal_assignment = renewal_benefit_group_assignment(coverage_date))

    renewal_assignment.benefit_group if renewal_assignment.benefit_group.plan_year.employees_are_matchable?
  end

  def off_cycle_published_benefit_package
    return unless (off_cycle_assignment = off_cycle_benefit_group_assignment)

    off_cycle_assignment.benefit_package if off_cycle_assignment.benefit_package.benefit_application.employees_are_matchable?
  end

  alias_method :renewal_published_benefit_group, :renewal_published_benefit_package

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

  def can_be_reinstated?
    self.employment_terminated? || self.cobra_terminated?
  end

  def reinstate_employment
    if self.may_reinstate_eligibility?
      self.update_attributes({:employment_terminated_on => nil, :coverage_terminated_on => nil})
      reinstate_eligibility!
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

  def generate_and_save_to_temp_folder
    begin
      url = Settings.checkbook_services.url
      event_kind = ApplicationEventKind.where(:event_name => 'out_of_pocker_url_notifier').first
      notice_trigger = event_kind.notice_triggers.first
      builder = notice_class(notice_trigger.notice_builder).new(self, {
        template: notice_trigger.notice_template,
        subject: event_kind.title,
        event_name: event_kind.event_name,
        mpi_indicator: notice_trigger.mpi_indicator,
        data: url
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences))
      builder.build_and_save
    rescue Exception => e
     Rails.logger.warn("Unable to build checkbook notice for #{e}")
    end
  end

  def generate_and_deliver_checkbook_url
    begin
      url = Settings.checkbook_services.url
      event_kind = ApplicationEventKind.where(:event_name => 'out_of_pocker_url_notifier').first
      notice_trigger = event_kind.notice_triggers.first
      builder = notice_class(notice_trigger.notice_builder).new(self, {
        template: notice_trigger.notice_template,
        subject: event_kind.title,
        event_name: event_kind.event_name,
        mpi_indicator: notice_trigger.mpi_indicator,
        data: url
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences))
      builder.deliver
   rescue Exception => e
      Rails.logger.warn("Unable to deliver checkbook url #{e}")
    end
  end

  def fetch_all_enrollments(employment_terminated_on)
    term_eligible_active_enrollments = active_benefit_group_enrollments(employment_terminated_on).show_enrollments_sans_canceled.non_terminated if active_benefit_group_enrollments(employment_terminated_on).present?
    term_eligible_renewal_enrollments = renewal_benefit_group_enrollments(employment_terminated_on).show_enrollments_sans_canceled.non_terminated if renewal_benefit_group_enrollments(employment_terminated_on).present?
    term_eligible_off_cycle_enrollments = off_cycle_benefit_group_enrollments.show_enrollments_sans_canceled.non_terminated if off_cycle_benefit_group_enrollments.present?
    expired_benefit_group_assignment = benefit_group_assignments.sort_by(&:created_at).select{ |bga| (bga.benefit_group.start_on..bga.benefit_group.end_on).include?(coverage_terminated_on) && bga.plan_year.aasm_state == :expired}.last
    term_eligible_expired_enrollments = expired_benefit_group_enrollments(expired_benefit_group_assignment.benefit_group).show_enrollments_sans_canceled.non_terminated if expired_benefit_group_assignment.present?
    (Array.wrap(term_eligible_active_enrollments) + Array.wrap(term_eligible_off_cycle_enrollments) + Array.wrap(term_eligible_renewal_enrollments) + Array.wrap(term_eligible_expired_enrollments)).compact.uniq
  end

  # rubocop:disable Metrics/CyclomaticComplexity

  def terminate_employee_enrollments(employment_terminated_on)
    fetch_all_enrollments(employment_terminated_on).each do |enrollment|
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

  # rubocop:enable Metrics/CyclomaticComplexity

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

  def is_cobra_possible?
    return false if cobra_linked? || cobra_eligible? || rehired? || cobra_terminated?
    return true if self.employment_terminated_on.present?
    return true if PENDING_STATES.include?(self.aasm_state)

    !(is_eligible? || employee_role_linked?)
  end

  def is_rehired_possible?
    return false if cobra_linked? || cobra_eligible? || rehired?
    return true if employment_terminated? || cobra_terminated?

    !(is_eligible? || employee_role_linked?)
  end

  def is_terminate_possible?
    return true if employment_terminated? || cobra_terminated?
    return false if cobra_linked?

    !(is_eligible? || is_linked?)
  end

  def employee_relationship
    "employee"
  end

  def assign_benefit_packages
    return true if is_case_old?
    # These will assign deafult benefit packages if not present
    self.active_benefit_group_assignment = nil
    self.renewal_benefit_group_assignment = nil
  end

  def active_benefit_group_assignment=(benefit_package_id)
    benefit_application = benefit_sponsorship&.benefit_package_by(benefit_package_id)&.benefit_application || benefit_sponsorship&.current_benefit_application

    if benefit_application.present? && !benefit_application.terminated?
      benefit_packages = benefit_package_id.present? ? [benefit_application.benefit_packages.find(benefit_package_id)] : benefit_application.benefit_packages
    end

    return unless benefit_packages.present? && (active_benefit_group_assignment.blank? || !benefit_packages.map(&:id).include?(active_benefit_group_assignment.benefit_package.id))

    create_benefit_group_assignment(benefit_packages)
  end

  def off_cycle_benefit_group_assignment=(benefit_package_id = nil)
    benefit_packages = fetch_off_cycle_benefit_packages(benefit_package_id)

    return unless benefit_packages.present? && (off_cycle_benefit_group_assignment.blank? || !benefit_packages.map(&:id).include?(off_cycle_benefit_group_assignment.benefit_package.id))

    create_benefit_group_assignment(benefit_packages, off_cycle: true)
  end

  def fetch_off_cycle_benefit_packages(benefit_package_id)
    benefit_application = benefit_sponsorship&.benefit_package_by(benefit_package_id)&.benefit_application || benefit_sponsorship&.off_cycle_benefit_application
    return unless benefit_application

    benefit_package_id.present? ? [benefit_application.benefit_packages.find(benefit_package_id)] : benefit_application.benefit_packages
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

  def send_invite!
    if has_benefit_group_assignment?
      benefit_application = active_benefit_group_assignment.benefit_package.benefit_application
      if benefit_application.is_submitted?
        Invitation.invite_employee_for_open_enrollment!(self)
        return true
      end
    end
    false
  end

  def construct_employee_role
    return @construct_role if defined? @construct_role
    @construct_role = true

    if active_benefit_group_assignment.present?
      if !Rails.env.test?
        send_invite! if _id_changed? && !self.benefit_sponsorship.is_conversion?
      end
      # we do not want to create employer role durig census employee saving for conversion
      # return if self.employer_profile.is_a_conversion_employer? ### this check needs to be re-done when loading mid_PY conversion and needs to have more specific check.

      if employee_role.present?
        self.link_employee_role! if may_link_employee_role? && employee_record_claimed?
      else
        construct_employee_role_for_match_person if has_benefit_group_assignment?
      end
    end
  end

  def construct_employee_role_for_match_person
    employee_relationship = Forms::EmployeeCandidate.new({first_name: first_name,
                                                          last_name: last_name,
                                                          ssn: ssn,
                                                          gender: gender,
                                                          dob: dob.strftime("%Y-%m-%d")})
    person = employee_relationship.match_person if employee_relationship.present?

    return false if person.blank? || (person.present? &&
                                      person.has_active_employee_role_for_census_employee?(self))
    Factories::EnrollmentFactory.build_employee_role(person, nil, employer_profile, self, hired_on)
    # self.trigger_notices("employee_eligibility_notice")#sends EE eligibility notice to census employee
    return true
  end

  def newhire_enrollment_eligible?
    active_benefit_group_assignment.present?
  end

  # Deprecated in Main app
  def has_active_health_coverage?(plan_year) # Related code is commented out
    benefit_group_ids = plan_year.benefit_groups.map(&:id)

    bg_assignment = active_benefit_group_assignment if benefit_group_ids.include?(active_benefit_group_assignment.try(:benefit_group_id))
    bg_assignment = renewal_benefit_group_assignment if benefit_group_ids.include?(renewal_benefit_group_assignment.try(:benefit_group_id))

    bg_assignment.present? && HbxEnrollment.enrolled_shop_health_benefit_group_ids([bg_assignment]).present?
  end

  def current_state
    if existing_cobra
      if COBRA_STATES.include? aasm_state
        aasm_state.humanize
      else
        'Cobra'
      end
    else
      aasm_state.humanize
    end
  end

  def trigger_notice(event)
    begin
      ShopNoticesNotifierJob.perform_later(self.id.to_s, event)
    rescue Exception => e
      Rails.logger.error { "Unable to deliver #{event.humanize} - notice to census employee - #{self.full_name} due to #{e}" }
    end
  end

  def update_for_cobra(cobra_date,current_user=nil)
    self.cobra_begin_date = cobra_date
    self.elect_cobra(current_user)
    self.save
  rescue => e
    false
  end

  def need_to_build_renewal_hbx_enrollment_for_cobra?
    renewal_benefit_group_assignment.present? && active_benefit_group_assignment != renewal_benefit_group_assignment
  end

  def build_hbx_enrollment_for_cobra
    family = employee_role.person.primary_family

    cobra_eligible_enrollments.each do |enrollment|
      factory = Factories::FamilyEnrollmentCloneFactory.new(
        family: family,
        census_employee: self,
        enrollment: enrollment
      )
      factory.clone_for_cobra
    end
  rescue => e
    logger.error(e)
  end

  class << self

    def download_census_employees_roster(employer_profile_id)
      columns = [
        "Family ID # (to match family members to the EE & each household gets a unique number)(optional)",
        "Relationship (EE, Spouse, Domestic Partner, or Child)",
        "Last Name",
        "First Name",
        "Middle Name or Initial (optional)",
        "Suffix (optional)",
        "Email Address",
        "SSN / TIN (Required for EE & enter without dashes)",
        "Date of Birth (MM/DD/YYYY)",
        "Gender",
        "Date of Hire",
        "Date of Termination (optional)",
        "Is Business Owner?",
        "Benefit Group (optional)",
        "Plan Year (Optional)",
        "Address Kind(Optional)",
        "Address Line 1(Optional)",
        "Address Line 2(Optional)",
        "City(Optional)",
        "State(Optional)",
        "Zip(Optional)"
      ]

      CSV.generate(headers: true) do |csv|
        csv << (["#{Settings.site.long_name} Employee Census Template"] +  6.times.collect{ "" } + [Date.new(2016,10,26)] + 5.times.collect{ "" } + ["1.1"])
        csv << %w(employer_assigned_family_id employee_relationship last_name first_name  middle_name name_sfx  email ssn dob gender  hire_date termination_date  is_business_owner benefit_group plan_year kind  address_1 address_2 city  state zip)
        csv << columns
        census_employees_query_criteria(employer_profile_id).each do |rec|
          is_active = rec["benefit_group_assignments"].present? ? rec["benefit_group_assignments"].any?{|bga| (bga["start_on"]..bga["end_on"]).cover?(TimeKeeper.date_of_record)} : false
          csv << insert_census_data(rec, is_active)

          if rec["census_dependents"].present?
            rec["census_dependents"].each do |dependent|
              csv << insert_census_data(dependent, is_active)
            end
          end
        end
      end
    end

    def insert_census_data(rec, is_active)
      values = [
        rec["employer_assigned_family_id"],
        relationship_mapping[rec["employee_relationship"]],
        rec["last_name"],
        rec["first_name"],
        rec["middle_name"],
        rec["name_sfx"],
        rec["email"].present? ? rec["email"]["address"] : nil,
        SymmetricEncryption.decrypt(rec["encrypted_ssn"]),
        rec["dob"].present? ? rec["dob"].strftime("%m/%d/%Y") : nil,
        rec["gender"]
      ]

      if is_active
        if rec["hired_on"].present?
          values += [
            rec["hired_on"].present? ? rec["hired_on"].strftime("%m/%d/%Y") : "",
            rec["employment_terminated_on"].present? ? rec["employment_terminated_on"].strftime("%m/%d/%Y") : "",
            rec["is_business_owner"] ? "yes" : "no"
          ]
        else
          values += ["", "", "no"]
        end

        values += 2.times.collect{ "" }
        if rec["address"].present?
          array = []
          array.push(rec["address"]["kind"])
          array.push(rec["address"]["address_1"])
          array.push(rec["address"]["address_2"].to_s)
          array.push(rec["address"]["city"])
          array.push(rec["address"]["state"])
          array.push(rec["address"]["zip"])
          values += array
        else
          values += 6.times.collect{ "" }
        end
      end

      values
    end

    def relationship_mapping
      {
        "self" => "employee",
        "spouse" => "spouse",
        "domestic_partner" => "domestic partner",
        "child_under_26" => "child",
        "disabled_child_26_and_over" => "disabled child"
      }
    end

    def census_employees_query_criteria(employer_profile_id)
      CensusEmployee.collection.aggregate(
        [
          {'$match' => {
            'benefit_sponsors_employer_profile_id' => employer_profile_id
          }},
          {"$sort" => {"last_name" => 1, "first_name" => 1}},
          { "$project" => { "first_name" => 1, "last_name" => 1, "middle_name" => 1, "name_sfx" => 1,
                            "dob" => 1, "gender" => 1, "hired_on" => 1, "aasm_state" => 1, "encrypted_ssn" =>1,
                            "employment_terminated_on" => 1,
                            "email.address" => 1, "address" => 1, "employee_relationship" => 1,"is_business_owner" => 1,
                            "employer_assigned_family_id" => 1,
                            "census_dependents" => { "$concatArrays" => ["$census_dependents", "$census_dependents.email", "$census_dependents.address"] } } },
        ],
        :allow_disk_use => true
      )
    end

    def scoped_profile(employer_profile_id)
      if EmployerProfile.find(employer_profile_id).is_a?(EmployerProfile)
        by_old_employer_profile_id(employer_profile_id)
      else
        by_benefit_sponsor_employer_profile_id(employer_profile_id)
      end
    end

    def enrolled_count(benefit_group)

        return 0 unless benefit_group

        cnt = CensusEmployee.collection.aggregate([
        {"$match" => {"benefit_group_assignments.benefit_group_id" => benefit_group.id  }},
        {"$unwind" => "$benefit_group_assignments"},
        {"$match" => {"aasm_state" => { "$in" =>  EMPLOYMENT_ACTIVE_STATES  } }},
        {"$match" => {"benefit_group_assignments.aasm_state" => { "$in" => ["coverage_selected"]} }},
        #{"$match" => {"benefit_group_assignments.is_active" => true}},
        {"$match" => {"benefit_group_assignments.benefit_group_id" => benefit_group.id  }},
        {"$group" => {
            "_id" =>  { "bgid" => "$benefit_group_assignments.benefit_group_id",
                        #"state" => "$aasm_state",
                        #{}"active" => "$benefit_group_assignments.is_active",
                        #{}"bgstate" => "$benefit_group_assignments.aasm_state"
                      },
                      "count" => { "$sum" => 1 }
                    }
              },
        #{"$match" => {"count" => {"$gte" => 1}}}
      ],
      :allow_disk_use => true)


      if cnt.count >= 1
        return cnt.first['count']
      else
        return 0
      end
    end

    # Advances the day for the employer and does the following:
    #   terminate_scheduled_census_employees
    #   rebase_newly_designated_employees
    #   terminate_future_scheduled_census_employees
    #   initial_employee_open_enrollment_notice
    #
    # @param new_date [Date]
    def advance_day(new_date)
      CensusEmployee.terminate_scheduled_census_employees
      CensusEmployee.rebase_newly_designated_employees
      CensusEmployee.terminate_future_scheduled_census_employees(new_date)
      CensusEmployee.initial_employee_open_enrollment_notice(new_date)
      # CensusEmployee.census_employee_open_enrollment_reminder_notice(new_date)
    end

    # Sends the initial open enrollment notices for all of the employers employees
    # @param new_date [Date]
    def initial_employee_open_enrollment_notice(date)
      census_employees = CensusEmployee.where(:"hired_on" => date).non_terminated
      census_employees.each do |ce|
        begin
          Invitation.invite_future_employee_for_open_enrollment!(ce)
        rescue Exception => e
          (Rails.logger.error { "Unable to deliver open enrollment notice to #{ce.full_name} due to --- #{e}" }) unless Rails.env.test?
        end
      end
    end

    def terminate_scheduled_census_employees(as_of_date = TimeKeeper.date_of_record)
      census_employees_for_termination = CensusEmployee.pending.where(:employment_terminated_on.lt => as_of_date)
      census_employees_for_termination.each do |census_employee|
        begin
          census_employee.terminate_employment(census_employee.employment_terminated_on)
        rescue Exception => e
          (Rails.logger.error { "Error while terminating cesus employee - #{census_employee.full_name} due to -- #{e}" }) unless Rails.env.test?
        end
      end
    end

    def rebase_newly_designated_employees
      return unless TimeKeeper.date_of_record.yday == 1
      CensusEmployee.where(:"aasm_state".in => NEWLY_DESIGNATED_STATES).each do |employee|
        begin
          employee.rebase_new_designee! if employee.may_rebase_new_designee?
        rescue Exception => e
          (Rails.logger.error { "Error while rebasing newly designated cesus employee - #{employee.full_name} due to #{e}" }) unless Rails.env.test?
        end
      end
    end

    def terminate_future_scheduled_census_employees(as_of_date)
      census_employees_for_termination = CensusEmployee.where(:aasm_state => "employee_termination_pending").select { |ce| ce.employment_terminated_on <= as_of_date}
      census_employees_for_termination.each do |census_employee|
        begin
          census_employee.terminate_employee_role!
        rescue Exception => e
          (Rails.logger.error { "Error while terminating future scheduled cesus employee - #{census_employee.full_name} due to #{e}" }) unless Rails.env.test?
        end
      end
    end

    # Deprecate in future

    def find_all_by_employer_profile(employer_profile)
      return unscoped.where(employer_profile_id: employer_profile._id).order_name_asc if employer_profile.is_a?(EmployerProfile)
      employer_profile.census_employees.order_name_asc
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

        query = unscoped.terminated.any_in(benefit_sponsors_employer_profile_id: employer_profile_ids).
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
          if person.ssn.nil?
            ce.unset(:encrypted_ssn)
          else
            ce.ssn = person.ssn
          end
          ce.dob = person.dob
          ce.save!(validate: false)
        end
      end
    end

    # Search query string on census employee with first name,last name,SSN.
    def search_hash(s_rex)
      clean_str = s_rex.strip.split.map{|i| Regexp.escape(i)}.join("|")
      action = s_rex.strip.split.size > 1 ? "$and" : "$or"
      search_rex = Regexp.compile(clean_str, true)
      {
          "$or" => [
              {action => [
                  {"first_name" => search_rex},
                  {"last_name" => search_rex}
              ]},
              {"encrypted_ssn" => encrypt_ssn(clean_str)}
          ]
      }
    end
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

  def self.roster_import_fallback_match(f_name, l_name, dob, bg_id)
    fname_exp = ::Regexp.compile(::Regexp.escape(f_name), true)
    lname_exp = ::Regexp.compile(::Regexp.escape(l_name), true)
    self.where({
      first_name: fname_exp,
      last_name: lname_exp,
      dob: dob
    }).any_in("benefit_group_assignments.benefit_group_id" => [bg_id])
  end

  def existing_cobra
    COBRA_STATES.include? aasm_state
  end

  def trigger_notices(event_name)
    begin
      ShopNoticesNotifierJob.perform_later(self.id.to_s, event_name)
    rescue Exception => e
      Rails.logger.error { "Unable to deliver #{event_name.humanize} to #{self.full_name} due to #{e}" }
    end
  end

  def existing_cobra=(cobra)
    self.aasm_state = 'cobra_eligible' if cobra == 'true'
  end

  def is_cobra_status?
    existing_cobra
  end

  def can_elect_cobra?
    ['employment_terminated'].include?(aasm_state)
  end

  def have_valid_date_for_cobra?(current_user = nil)
    return false unless cobra_begin_date.present?
    return false unless coverage_terminated_on
    return false unless coverage_terminated_on <= cobra_begin_date

    (hired_on <= cobra_begin_date) &&
      (TimeKeeper.date_of_record <= (coverage_terminated_on + aca_shop_market_cobra_enrollment_period_in_months.months)) &&
      cobra_begin_date <= (coverage_terminated_on + aca_shop_market_cobra_enrollment_period_in_months.months)
  end

  def has_employee_role_linked?
    employee_role.present?
  end

  # Verifies whether roster employee is cobra eligible or not
  #
  # Rules for employee cobra eligibility:
  # * Employee must be in a terminated status
  # * Must be a covered employee on the date of their employment termination
  # @return [Boolean]
  def is_cobra_coverage_eligible?
    return false unless self.employment_terminated?

    Family.where(:"households.hbx_enrollments" => {
      :$elemMatch => {
        :benefit_group_assignment_id.in => benefit_group_assignments.pluck(:id),
        :coverage_kind => 'health',
        :kind => 'employer_sponsored',
        :terminated_on => coverage_terminated_on || employment_terminated_on.end_of_month,
        :aasm_state.in => ['coverage_terminated', 'coverage_termination_pending']}
    }).present?
  end

  ##
  # This is to validate 6 months rule for cobra eligiblity
  def cobra_eligibility_expired?
    last_date_of_coverage = (coverage_terminated_on || employment_terminated_on.end_of_month)
    TimeKeeper.date_of_record > last_date_of_coverage + 6.months
  end

  def has_cobra_hbx_enrollment?
    return false if active_benefit_group_assignment.blank?
    enrollments_for_display.detect{|enrollment| enrollment.is_cobra_status? && (HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::WAIVED_STATUSES).include?(enrollment.aasm_state)}
  end

  def need_update_hbx_enrollment_effective_on?
    !has_cobra_hbx_enrollment? && coverage_terminated_on.present?
  end

  def show_plan_end_date?
    is_inactive? && coverage_terminated_on.present?
  end

  def is_included_in_participation_rate?
    return true if coverage_terminated_on.nil?
    return false if active_benefit_group_assignment.nil?
    coverage_terminated_on >= active_benefit_group_assignment.start_on
  end

  def enrollments_for_display
    enrollments = []

    coverages_selected = lambda do |enrollments|
      return [] if enrollments.blank?
      coverages = enrollments.non_expired_and_non_terminated.non_external
      [coverages.detect{|c| c.coverage_kind == 'health'}, coverages.detect{|c| c.coverage_kind == 'dental'}]
    end

    enrollments += coverages_selected.call(active_benefit_group_enrollments)
    enrollments += coverages_selected.call(renewal_benefit_group_enrollments)
    enrollments += coverages_selected.call(off_cycle_benefit_group_enrollments)
    enrollments.compact.uniq
  end

  def expected_to_enroll?
    expected_selection == 'enroll'
  end

  def expected_to_enroll_or_valid_waive?
    %w(enroll waive).include?  expected_selection
  end

  def waived?
    bga = renewal_benefit_group_assignment || active_benefit_group_assignment
    bga.present? ? bga&.hbx_enrollment&.aasm_state == 'coverage_waived' : false
  end

  # TODO: Implement for 16219
  def composite_rating_tier
    return CompositeRatingTier::EMPLOYEE_ONLY if self.census_dependents.empty?
    relationships = self.census_dependents.map(&:employee_relationship)
    if (relationships.include?("spouse") || relationships.include?("domestic_partner"))
      relationships.many? ? CompositeRatingTier::FAMILY : CompositeRatingTier::EMPLOYEE_AND_SPOUSE
    else
      CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
    end
  end

  def past_benefit_group_assignments
    benefit_group_assignments - [active_benefit_group_assignment, renewal_benefit_group_assignment].compact
  end

  def past_enrollments
    if employee_role.present?
      query = {
        :aasm_state.in => ["coverage_terminated", "coverage_termination_pending","coverage_expired"],
        :benefit_group_assignment_id.in => benefit_group_assignments.map(&:id)
      }
      employee_role.person.primary_family.active_household.hbx_enrollments.non_external.shop_market.where(query)
    end
  end

  def is_employee_in_term_pending?
    return false if employment_terminated_on.blank?
    return false if active_benefit_group_assignment.blank?
    return false if is_cobra_status?

    effective_period = active_benefit_group_assignment.benefit_package.effective_period
    employment_terminated_on <= effective_period.max
  end

  # Enrollments with current active and renewal benefit applications
  def active_benefit_group_enrollments(coverage_date = TimeKeeper.date_of_record)
    return nil if employee_role.blank?

    HbxEnrollment.where(
      {
        :sponsored_benefit_package_id.in => [active_benefit_group(coverage_date).try(:id)].compact,
        :employee_role_id => self.employee_role_id,
        :aasm_state.ne => "shopping"
      }
    ) || []
  end

  def renewal_benefit_group_enrollments(coverage_date = nil)
    return nil if employee_role.blank?

    HbxEnrollment.where(
      {
        :sponsored_benefit_package_id.in => [renewal_published_benefit_group(coverage_date).try(:id)].compact,
        :employee_role_id => self.employee_role_id,
        :aasm_state.ne => "shopping"
      }
    ) || []
  end

  def off_cycle_benefit_group_enrollments
    return nil if employee_role.blank?

    HbxEnrollment.where(
      {
        :sponsored_benefit_package_id.in => [off_cycle_published_benefit_package.try(:id)].compact,
        :employee_role_id => self.employee_role_id,
        :aasm_state.ne => "shopping"
      }
    ) || []
  end

  def expired_benefit_group_enrollments(expired_benefit_group)
    return nil if employee_role.blank?
    HbxEnrollment.where({
                            :"sponsored_benefit_package_id".in => [expired_benefit_group.id].compact,
                            :"employee_role_id" => self.employee_role_id,
                            :"aasm_state".ne => "shopping"
                        }) || []
  end

  # Enrollments eligible for Cobra

  # Picking latest health & dental enrollments
  def active_benefit_group_cobra_eligible_enrollments
    return [] if active_benefit_group_enrollments.blank?
    eligible_enrollments = active_benefit_group_enrollments.non_cobra.enrollments_for_cobra
    [eligible_enrollments.by_health.first, eligible_enrollments.by_dental.first].compact
  end

  # Picking latest health & dental enrollments
  def renewal_benefit_group_cobra_eligible_enrollments
    return [] if renewal_benefit_group_enrollments.blank?
    eligible_enrollments = renewal_benefit_group_enrollments.non_cobra.enrollments_for_cobra
    [eligible_enrollments.by_health.first, eligible_enrollments.by_dental.first].compact
  end

  # Picking latest health & dental enrollments
  def off_cycle_benefit_group_cobra_eligible_enrollments
    return [] if off_cycle_benefit_group_enrollments.blank?

    eligible_enrollments = off_cycle_benefit_group_enrollments.non_cobra.enrollments_for_cobra
    [eligible_enrollments.by_health.first, eligible_enrollments.by_dental.first].compact
  end

  def cobra_eligible_enrollments
    (active_benefit_group_cobra_eligible_enrollments + off_cycle_benefit_group_cobra_eligible_enrollments + renewal_benefit_group_cobra_eligible_enrollments).flatten
  end

  # Retrieves the last updated benefit_group_assignment with a given +package_id+ & +start_on+
  # @param package_id & start_on [Integer]
  # @return [BenefitGroupAssignment]
  def benefit_group_assignment_by_package(package_id, start_on)
    # benefit_group_assignments.where(benefit_package_id: package_id).order_by(:'updated_at'.desc).first
    benefit_group_assignments.detect { |benefit_group_assignment| benefit_group_assignment.benefit_package_id == package_id && benefit_group_assignment.is_active?(start_on) }
  end

  def benefit_package_for_date(coverage_date)
    # benefit_assignment = benefit_group_assignment_for_date(coverage_date)
    benefit_assignment = benefit_package_assignment_on(coverage_date)
    benefit_package = benefit_assignment.benefit_package if benefit_assignment.present?
    benefit_package&.is_conversion? ? nil : benefit_package
  end

  # Retrieves the benefit_group_assignment that covers the passed +coverage_date+
  # and returns the first active one or the first one found.
  # @param coverage_date [Date]
  # @return [BenefitGroupAssignment]
  def benefit_group_assignment_for_date(coverage_date)
    assignments = benefit_group_assignments.select do |assignment|
      (assignment.start_on..assignment.benefit_end_date).cover?(coverage_date) && assignment.is_active?(coverage_date)
    end
    assignments.select { |assignment| assignment.is_active?(coverage_date) }.sort_by(&:created_at).reverse.first || assignments.sort_by(&:created_at).reverse.first
  end

  def is_waived_under?(benefit_application)
    assignment_by_application = [renewal_benefit_group_assignment, active_benefit_group_assignment].compact.detect do |assignment|
      assignment.benefit_application && (assignment.benefit_application == benefit_application)
    end
    return false if assignment_by_application.blank? || assignment_by_application.hbx_enrollment.blank?
    assignment_by_application.hbx_enrollment.is_coverage_waived?
  end

  def ssn=(new_ssn)
    if !new_ssn.blank?
      write_attribute(:encrypted_ssn, CensusMember.encrypt_ssn(new_ssn))
    else
      unset_sparse("encrypted_ssn")
    end
  end

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

  private

  def notice_class(notice_type)
    notice_class = ['ShopEmployerNotices::OutOfPocketNotice'].find { |notice| notice == notice_type.classify }
    raise "Unable to find the notice_class" if notice_class.nil?
    notice_type.safe_constantize
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event
    )
  end

  def set_autocomplete_slug
    return unless (first_name.present? && last_name.present?)
    @autocomplete_slug = first_name.concat(" #{last_name}")
  end

  def has_no_hbx_enrollments?
    return true if employee_role.blank?
    !benefit_group_assignments.detect { |bga| bga.hbx_enrollment.present? && !HbxEnrollment::CANCELED_STATUSES.include?(bga.hbx_enrollment.aasm_state)}
  end

  def check_employment_terminated_on
    return false if is_cobra_status?

    if employment_terminated_on && employment_terminated_on <= hired_on
      errors.add(:employment_terminated_on, "can't occur before hiring date")
    end

    if !self.employment_terminated? && !self.rehired?
      if employment_terminated_on && employment_terminated_on <= TimeKeeper.date_of_record - 60.days
        errors.add(:employment_terminated_on, "Employee termination must be within the past 60 days")
      end
    end
  end

  def check_cobra_begin_date
    if existing_cobra && hired_on > cobra_begin_date
      errors.add(:cobra_begin_date, 'must be after Hire Date')
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
    potential_dups = CensusEmployee.by_ssn(ssn).by_old_employer_profile_id(employer_profile_id).active if is_case_old?
    potential_dups ||= CensusEmployee.by_ssn(ssn).by_benefit_sponsor_employer_profile_id(benefit_sponsors_employer_profile_id).active
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
    if (ssn_changed? || dob_changed?) && !ELIGIBLE_STATES.include?(aasm_state)
      message = "An employee's identifying information may change only when in 'eligible' status. "
      errors.add(:base, message)
    end
  end

  def check_hired_on_before_dob
    if hired_on && dob && hired_on <= dob
      errors.add(:hired_on, "date can't be before  date of birth.")
    end
  end

  def clear_employee_role
    # employee_role.
    self.employee_role_id = nil
    unset("employee_role_id")
    self.benefit_group_assignments = []
    @employee_role = nil
  end

  def validate_unique_identifier
    if ssn && ssn.size != 9 && no_ssn_allowed == false
      errors.add(:ssn, "must be 9 digits.")
    elsif ssn.blank? && no_ssn_allowed == false
      errors.add(:ssn, "Can't be blank")
    end
  end

  def notify_terminated
    notify(EMPLOYEE_TERMINATED_EVENT_NAME, { :census_employee_id => self.id } )
  end

  def notify_cobra_terminated
    notify(EMPLOYEE_COBRA_TERMINATED_EVENT_NAME, { :census_employee_id => self.id } )
  end
end

class CensusEmployeeError < StandardError; end
