class BenefitGroupAssignment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  RENEWING = %w(coverage_renewing)

  embedded_in :census_employee

  field :benefit_group_id, type: BSON::ObjectId

  # Represents the most recent completed enrollment
  field :hbx_enrollment_id, type: BSON::ObjectId

  field :start_on, type: Date
  field :end_on, type: Date
  field :coverage_end_on, type: Date
  field :aasm_state, type: String, default: "initialized"
  field :is_active, type: Boolean, default: true
  field :activated_at, type: DateTime

  embeds_many :workflow_state_transitions, as: :transitional

  validates_presence_of :benefit_group_id, :start_on, :is_active
  validate :date_guards, :model_integrity

  scope :renewing,       ->{ any_in(aasm_state: RENEWING) }

  def self.by_benefit_group_id(bg_id)
    census_employees = CensusEmployee.where({
      "benefit_group_assignments.benefit_group_id" => bg_id
    })
    census_employees.flat_map(&:benefit_group_assignments).select do |bga|
      bga.benefit_group_id == bg_id
    end
  end

  class << self
    def find(id)
      ee = CensusEmployee.where(:"benefit_group_assignments._id" => id).first
      ee.benefit_group_assignments.detect { |bga| bga._id == id } unless ee.blank?
    end

    def new_from_group_and_census_employee(benefit_group, census_ee)
      census_ee.benefit_group_assignments.new(
        benefit_group_id: benefit_group._id,
        start_on: [benefit_group.start_on, census_ee.hired_on].compact.max
      )
    end
  end

  def plan_year
    benefit_group.plan_year if benefit_group
  end

  def belongs_to_offexchange_planyear?
    employer_profile = plan_year.employer_profile
    employer_profile.is_coversion_employer? && plan_year.coverage_period_contains?(employer_profile.registered_on)
  end

  def benefit_group=(new_benefit_group)
    raise ArgumentError.new("expected BenefitGroup") unless new_benefit_group.is_a? BenefitGroup
    self.benefit_group_id = new_benefit_group._id
    @benefit_group = new_benefit_group
  end

  def benefit_group
    return @benefit_group if defined? @benefit_group
    return nil if benefit_group_id.blank?
    @benefit_group = BenefitGroup.find(self.benefit_group_id)
  end

  def hbx_enrollment=(new_hbx_enrollment)
    raise ArgumentError.new("expected HbxEnrollment") unless new_hbx_enrollment.is_a? HbxEnrollment
    self.hbx_enrollment_id = new_hbx_enrollment._id
    @hbx_enrollment = new_hbx_enrollment
  end

  def hbx_enrollments
    families = Family.where({
      "households.hbx_enrollments.benefit_group_assignment_id" => BSON::ObjectId.from_string(self.id)
      })

    families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.show_enrollments_sans_canceled.select do |enrollment| 
          enrollment.benefit_group_assignment_id == self.id
        end.to_a
      end
      enrollments
    end
  end

  def hbx_enrollment
    return @hbx_enrollment if defined? @hbx_enrollment

    if hbx_enrollment_id.blank?
      families = Family.where({
        "households.hbx_enrollments.benefit_group_assignment_id" => BSON::ObjectId.from_string(self.id)
        })

      families.each do |family|
        family.households.each do |household|
          household.hbx_enrollments.each do |enrollment|
            if enrollment.benefit_group_assignment_id == self.id
              @hbx_enrollment = enrollment
            end
          end
        end
      end

      return @hbx_enrollment
    else
      @hbx_enrollment = HbxEnrollment.find(self.hbx_enrollment_id)
    end
  end

  def end_benefit(end_on)
    return if coverage_waived?
    self.coverage_end_on = end_on
    terminate_coverage! if may_terminate_coverage?
  end

  aasm do
    state :initialized, initial: true
    state :coverage_selected
    state :coverage_waived
    state :coverage_terminated
    state :coverage_void
    state :coverage_renewing
    state :coverage_expired

    #FIXME create new hbx_enrollment need to create a new benefitgroup_assignment
    #then we will not need from coverage_terminated to coverage_selected
    event :select_coverage, :after => :record_transition do
      transitions from: [:initialized, :coverage_waived, :coverage_terminated, :coverage_renewing], to: :coverage_selected
    end

    event :waive_coverage, :after => :record_transition do
      transitions from: [:initialized, :coverage_selected, :coverage_renewing], to: :coverage_waived
    end

    event :renew_coverage, :after => :record_transition do
      transitions from: :initialized , to: :coverage_renewing
    end

    event :terminate_coverage, :after => :record_transition do
      transitions from: :initialized, to: :coverage_void
      transitions from: :coverage_selected, to: :coverage_terminated
      transitions from: :coverage_renewing, to: :coverage_terminated
    end

    event :expire_coverage, :after => :record_transition do
      transitions from: [:coverage_selected, :coverage_renewing], to: :coverage_expired, :guard  => :can_be_expired?
    end

    event :delink_coverage, :after => :record_transition do
      transitions from: [:coverage_selected, :coverage_waived, :coverage_terminated, :coverage_void], to: :initialized, after: :propogate_delink
    end
  end

  def waive_benefit
    waive_coverage! if may_waive_coverage?
    make_active
  end

  def begin_benefit
    select_coverage! if may_select_coverage?
    make_active
  end

  def make_active
    census_employee.benefit_group_assignments.each do |bg_assignment|
      if bg_assignment.is_active? && bg_assignment.id != self.id
        bg_assignment.update_attributes(is_active: false, end_on: [start_on - 1.day, bg_assignment.start_on].max)
      end
    end

    update_attributes(is_active: true, activated_at: TimeKeeper.datetime_of_record) unless is_active?
  end

  private

  def can_be_expired?
    benefit_group.end_on <= TimeKeeper.date_of_record
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

  def propogate_delink
    if hbx_enrollment.present?
      hbx_enrollment.terminate_coverage! if hbx_enrollment.may_terminate_coverage?
    end
    # self.hbx_enrollment_id = nil
  end

  def model_integrity
    self.errors.add(:benefit_group, "benefit_group required") unless benefit_group.present?

    if coverage_selected?
      self.errors.add(:hbx_enrollment, "hbx_enrollment required") if hbx_enrollment.blank?
    end

    if hbx_enrollment.present?
      self.errors.add(:hbx_enrollment, "benefit group missmatch") unless hbx_enrollment.benefit_group_id == benefit_group_id
      # TODO: Re-enable this after enrollment propagation issues resolved. 
      #       Right now this is causing issues when linking census employee under Enrollment Factory.
      # self.errors.add(:hbx_enrollment, "employee_role missmatch") if hbx_enrollment.employee_role_id != census_employee.employee_role_id and census_employee.employee_role_linked?
    end
  end

  def date_guards
    return unless benefit_group.present? && start_on.present?

    unless (self.benefit_group.plan_year.start_on..self.benefit_group.plan_year.end_on).cover?(start_on)
      errors.add(:start_on, "can't occur outside plan year dates")
    end

    if end_on.present?
      unless (self.benefit_group.plan_year.start_on..self.benefit_group.plan_year.end_on).cover?(end_on)
        errors.add(:end_on, "can't occur outside plan year dates")
      end

      if end_on < start_on
        errors.add(:end_on, "can't occur before start date")
      end
    end
  end

end
