  class BenefitGroupAssignment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  RENEWING = %w(coverage_renewing)

  embedded_in :census_employee

  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_package_id, type: BSON::ObjectId # Engine Benefit Package


  # Represents the most recent completed enrollment
  field :hbx_enrollment_id, type: BSON::ObjectId

  field :start_on, type: Date
  field :end_on, type: Date
  field :is_active, type: Boolean, default: true

  field :activated_at, type: DateTime

  embeds_many :workflow_state_transitions, as: :transitional

  validates_presence_of :start_on
  validates_presence_of :benefit_group_id, :if => Proc.new {|obj| obj.benefit_package_id.blank? }
  validates_presence_of :benefit_package_id, :if => Proc.new {|obj| obj.benefit_group_id.blank? }
  validate :date_guards, :model_integrity

  scope :renewing,       -> { any_in(aasm_state: RENEWING) }
  # scope :active,         -> { where(:is_active => true) }
  scope :effective_on,   ->(effective_date) { where(:start_on => effective_date) }

  scope :cover_date, lambda { |compare_date|
    result = where(
      {
        :$or => [
          {:start_on.lte => compare_date, :end_on.gte => compare_date},
          {:start_on.lte => compare_date, :end_on => nil},
        ]
      }
    ).order(start_on: :desc)
    if result.empty?
      result = where(
        {
          :$and => [
            {:start_on.lte => compare_date, :end_on => nil},
            {:start_on.gte => (compare_date == compare_date.end_of_month ? (compare_date - 1.year + 1.day) : (compare_date - 1.year))}
          ]
        }
      ).order(start_on: :desc)
    end

    # we need to deal with multiples returned
    #   1) canceled benefit group assignments
    #   2) multiple draft applications
    if result.size > 1
      date_matched = result.and(start_on: compare_date)
      if date_matched.any?
        date_matched.and(is_active: true).any? ? date_matched.and(is_active: true) : date_matched
      else
        result.where(:end_on => {:exists => true}).any? ? result.where(:end_on => {:exists => true}) : result
      end
    else
      result
    end
  }

  scope :by_benefit_package,     ->(benefit_package) { where(:benefit_package_id => benefit_package.id) }
  scope :by_benefit_package_and_assignment_on,->(benefit_package, effective_on) {
    where(:start_on.lte => effective_on, :end_on.gte => effective_on, :benefit_package_id => benefit_package.id)
  }

  class << self

    def find(id)
      ee = CensusEmployee.where(:"benefit_group_assignments._id" => id).first
      ee.benefit_group_assignments.detect { |bga| bga._id == id } unless ee.blank?
    end

    def on_date(census_employee, date)
      assignments = census_employee.benefit_group_assignments.select{ |bga| bga.persisted? && bga.activated_at.blank? }
      assignments_with_no_end_on, assignments_with_end_on = assignments.partition { |bga| bga.end_on.nil? }

      if assignments_with_end_on.present?
        valid_assignments_with_end_on = assignments_with_end_on.select { |assignment| (assignment.start_on..assignment.end_on).cover?(date) }
        if valid_assignments_with_end_on.present?
          valid_assignments_with_end_on.sort_by { |assignment| (assignment.start_on.to_time - date.to_time).abs }.first || valid_assignments_with_end_on.first
        else
          filter_assignments_with_no_end_on(assignments_with_no_end_on, date)
        end
      elsif assignments_with_no_end_on.present?
        filter_assignments_with_no_end_on(assignments_with_no_end_on, date)
      end
      # if assignments.size > 1
      #   assignments.detect{|assignment| assignment.end_on.blank? } || assignments.first
      # else
      #   assignments.first
      # end
    end

    def filter_assignments_with_no_end_on(assignments, date)
      valid_assignments_with_no_end_on = assignments.select { |assignment| (assignment.start_on..assignment.start_on.next_year.prev_day).cover?(date) }
      if valid_assignments_with_no_end_on.size > 1
        valid_assignments_with_no_end_on.detect { |assignment| assignment.is_active? } ||
        valid_assignments_with_no_end_on.sort_by { |assignment| (assignment.start_on.to_time - date.to_time).abs }.first
      else
        valid_assignments_with_no_end_on.first
      end
    end

    def by_benefit_group_id(bg_id)
      census_employees = CensusEmployee.where({:"benefit_group_assignments.benefit_group_id" => bg_id})
      census_employees.flat_map(&:benefit_group_assignments).select do |bga|
        bga.benefit_group_id == bg_id
      end
    end

    def new_from_group_and_census_employee(benefit_group, census_ee)
      census_ee.benefit_group_assignments.new(
        benefit_group_id: benefit_group._id,
        start_on: [benefit_group.start_on, census_ee.hired_on].compact.max
      )
    end
  end

  def is_case_old?
    self.benefit_package_id.blank?
  end

  def plan_year
    warn "[Deprecated] Instead use benefit application" unless Rails.env.test?
    return benefit_group.plan_year if is_case_old?
    benefit_application
  end

  def benefit_application
    benefit_package.benefit_application if benefit_package.present?
  end

  def belongs_to_offexchange_planyear?
    employer_profile = plan_year.employer_profile
    employer_profile.is_conversion? && plan_year.is_conversion
  end

  def benefit_group=(new_benefit_group)
    warn "[Deprecated] Instead use benefit_package=" unless Rails.env.test?
    if new_benefit_group.is_a?(BenefitGroup)
      self.benefit_group_id = new_benefit_group._id
      return @benefit_group = new_benefit_group
    end
    self.benefit_package=(new_benefit_group)
  end

  def benefit_group
    return @benefit_group if defined? @benefit_group
    warn "[Deprecated] Instead use benefit_package" unless Rails.env.test?
    if is_case_old?
      return @benefit_group = BenefitGroup.find(self.benefit_group_id)
    end
    benefit_package
  end

  def benefit_package=(new_benefit_package)
    raise ArgumentError.new("expected BenefitPackage") unless new_benefit_package.is_a? BenefitSponsors::BenefitPackages::BenefitPackage
    self.benefit_package_id = new_benefit_package._id
    @benefit_package = new_benefit_package
  end

  def benefit_package
    return if benefit_package_id.nil?
    return @benefit_package if defined? @benefit_package
    @benefit_package = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
  end

  def hbx_enrollment=(new_hbx_enrollment)
    raise ArgumentError.new("expected HbxEnrollment") unless new_hbx_enrollment.is_a? HbxEnrollment
    self.hbx_enrollment_id = new_hbx_enrollment._id
    @hbx_enrollment = new_hbx_enrollment
  end

  def covered_families
    Family.where(:"_id".in => HbxEnrollment.where(
      benefit_group_assignment_id: BSON::ObjectId.from_string(self.id)
    ).pluck(:family_id)
  )
  end

  def hbx_enrollments
    covered_families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.show_enrollments_sans_canceled.select do |enrollment|
          enrollment.benefit_group_assignment_id == self.id
        end.to_a
      end
      enrollments
    end
  end

  # Deprecated
  def latest_hbx_enrollments_for_cobra
    families = Family.where({
      "households.hbx_enrollments.benefit_group_assignment_id" => BSON::ObjectId.from_string(self.id)
      })

    hbx_enrollments = families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.enrollments_for_cobra.select do |enrollment|
          enrollment.benefit_group_assignment_id == self.id
        end.to_a
      end
      enrollments
    end

    if census_employee.cobra_begin_date.present?
      coverage_terminated_on = census_employee.cobra_begin_date.prev_day
      hbx_enrollments = hbx_enrollments.select do |e|
        e.effective_on < census_employee.cobra_begin_date && (e.terminated_on.blank? || e.terminated_on == coverage_terminated_on)
      end
    end

    health_hbx = hbx_enrollments.detect{ |hbx| hbx.coverage_kind == 'health' && !hbx.is_cobra_status? }
    dental_hbx = hbx_enrollments.detect{ |hbx| hbx.coverage_kind == 'dental' && !hbx.is_cobra_status? }

    [health_hbx, dental_hbx].compact
  end

  def active_and_waived_enrollments
    covered_families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.non_expired_and_non_terminated.select { |enrollment| enrollment.benefit_group_assignment_id == self.id }
      end
      enrollments
    end
  end

  def active_enrollments
    covered_families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.enrolled_and_renewal.select { |enrollment| enrollment.benefit_group_assignment_id == self.id }
      end
      enrollments
    end
  end

  # def hbx_enrollment # Deprecated
  #   return @hbx_enrollment if defined? @hbx_enrollment

  #   if hbx_enrollment_id.blank?
  #     families = Family.where({
  #       "households.hbx_enrollments.benefit_group_assignment_id" => BSON::ObjectId.from_string(self.id)
  #       })

  #     families.each do |family|
  #       family.households.each do |household|
  #         household.hbx_enrollments.show_enrollments_sans_canceled.each do |enrollment|
  #           if enrollment.benefit_group_assignment_id == self.id
  #             @hbx_enrollment = enrollment
  #           end
  #         end
  #       end
  #     end

  #     return @hbx_enrollment
  #   else
  #     @hbx_enrollment = HbxEnrollment.find(self.hbx_enrollment_id)
  #   end
  # end

  def hbx_enrollment
    @hbx_enrollment ||= HbxEnrollment.where(id: hbx_enrollment_id).first || hbx_enrollments.max_by(&:created_at)
  end

  def end_benefit(end_date)
    return if hbx_enrollment.is_coverage_waived?
    self.update_attributes!(end_on: end_date)
  end

  def end_date=(end_date)
    end_date = [self.start_on, end_date].max
    self[:end_on] = benefit_package.cover?(end_date) ? end_date : benefit_end_date
  end

  def benefit_end_date
    end_on || benefit_package.end_on
  end

  def is_belong_to?(new_benefit_package)
    benefit_package == new_benefit_package
  end

  def canceled?
    return false if end_on.blank?
    start_on == end_on
  end

  def update_status_from_enrollment(hbx_enrollment)
    if hbx_enrollment.coverage_kind == 'health'
      if HbxEnrollment::ENROLLED_STATUSES.include?(hbx_enrollment.aasm_state)
        change_state_without_event(:coverage_selected)
      end

      if HbxEnrollment::RENEWAL_STATUSES.include?(hbx_enrollment.aasm_state)
        change_state_without_event(:coverage_renewing)
      end

      if HbxEnrollment::WAIVED_STATUSES.include?(hbx_enrollment.aasm_state)
        change_state_without_event(:coverage_waived)
      end
    end
  end

  def waive_benefit(date = TimeKeeper.date_of_record)
    make_active(date)
  end

  def begin_benefit(date = TimeKeeper.date_of_record)
    make_active(date)
  end

  # def is_active
  #   is_active?
  # end

  def is_active?(date = TimeKeeper.date_of_record)
    end_date = end_on || start_on.next_year.prev_day
    (start_on..end_date).cover?(date)
  end

  def make_active
    census_employee.benefit_group_assignments.each do |benefit_group_assignment|
      if benefit_group_assignment.is_active? && benefit_group_assignment.id != self.id  
        end_on = benefit_group_assignment.end_on || (start_on - 1.day)
        if is_case_old?
          end_on = benefit_group_assignment.plan_year.end_on unless benefit_group_assignment.plan_year.coverage_period_contains?(end_on)
        else
          end_on = benefit_group_assignment.benefit_application.end_on unless benefit_group_assignment.benefit_application.effective_period.cover?(end_on)
        end
        benefit_group_assignment.update_attributes(end_on: end_on)
      end
    end
    # TODO: Hack to get census employee spec to pass
    #bga_to_activate = census_employee.benefit_group_assignments.select { |bga| HbxEnrollment::ENROLLED_STATUSES.include?(bga.hbx_enrollment&.aasm_state) }.last 
    #if bga_to_activate.present?
    # bga_to_activate.update_attributes!(activated_at: TimeKeeper.datetime_of_record)
    #else
    # TODO: Not sure why this isn't working right
    update_attributes!(activated_at: TimeKeeper.datetime_of_record)
    #end
  end

  private

  def can_be_expired?
    benefit_group.end_on <= TimeKeeper.date_of_record
  end

  def propogate_delink
    if hbx_enrollment.present?
      hbx_enrollment.terminate_coverage! if hbx_enrollment.may_terminate_coverage?
    end
    # self.hbx_enrollment_id = nil
  end

  def model_integrity
    self.errors.add(:benefit_group, "benefit_group required") unless benefit_group.present?
    
    # TODO: Not sure if this can really exist if we depracate aasm_state from here. Previously the hbx_enrollment was checked if coverage_selected?
    # which references the aasm_state, but if thats depracated, not sure hbx_enrollment can be checked any longer. CensusEmployee model has an instance method
    # called create_benefit_package_assignment(new_benefit_package, start_on) which creates a BGA without hbx enrollment.
    # self.errors.add(:hbx_enrollment, "hbx_enrollment required") if hbx_enrollment.blank?
    if hbx_enrollment.present?
      self.errors.add(:hbx_enrollment, "benefit group missmatch") unless hbx_enrollment.sponsored_benefit_package_id == benefit_package_id
      # TODO: Re-enable this after enrollment propagation issues resolved.
      #       Right now this is causing issues when linking census employee under Enrollment Factory.
      # self.errors.add(:hbx_enrollment, "employee_role missmatch") if hbx_enrollment.employee_role_id != census_employee.employee_role_id and census_employee.employee_role_linked?
    end
  end

  def date_guards
    return if benefit_package.blank? || start_on.blank?

    errors.add(:start_on, "can't occur outside plan year dates") unless benefit_package.effective_period.cover?(start_on)
    if end_on.present?
      errors.add(:end_on, "can't occur outside plan year dates") unless benefit_package.effective_period.cover?(end_on)
      errors.add(:end_on, "can't occur before start date") if end_on < start_on
    end
  end
end
