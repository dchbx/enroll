require 'services/checkbook_services'

class CensusEmployee < CensusMember
  include AASM
  include Sortable
  include Searchable
  # include Validations::EmployeeInfo
  include Autocomplete
  include Acapi::Notifiers
  include ::Eligibility::CensusEmployee
  include ::Eligibility::EmployeeBenefitPackages

  require 'roo'

  EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
  EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated rehired cobra_terminated)
  NEWLY_DESIGNATED_STATES = %w(newly_designated_eligible newly_designated_linked)
  LINKED_STATES = %w(employee_role_linked newly_designated_linked cobra_linked)
  ELIGIBLE_STATES = %w(eligible newly_designated_eligible cobra_eligible employee_termination_pending cobra_termination_pending)
  COBRA_STATES = %w(cobra_eligible cobra_linked cobra_terminated cobra_termination_pending)
  PENDING_STATES = %w(employee_termination_pending cobra_termination_pending)

  EMPLOYEE_TERMINATED_EVENT_NAME = "acapi.info.events.census_employee.terminated"
  EMPLOYEE_COBRA_TERMINATED_EVENT_NAME = "acapi.info.events.census_employee.cobra_terminated"

  field :is_business_owner, type: Boolean, default: false
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :coverage_terminated_on, type: Date
  field :aasm_state, type: String

  # Employer for this employee
  field :employer_profile_id, type: BSON::ObjectId
  field :benefit_sponsor_employer_profile_id, type: BSON::ObjectId

  # Employee linked to this roster record
  field :employee_role_id, type: BSON::ObjectId

  field :cobra_begin_date, type: Date

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
  validate :check_cobra_begin_date
  validate :check_hired_on_before_dob
  after_update :update_hbx_enrollment_effective_on_by_hired_on
  after_save :assign_default_benefit_package

  before_save :allow_nil_ssn_updates_dependents
  after_save :construct_employee_role

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

  scope :active,            ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
  scope :terminated,        ->{ any_in(aasm_state: EMPLOYMENT_TERMINATED_STATES) }
  scope :non_terminated,    ->{ where(:aasm_state.nin => EMPLOYMENT_TERMINATED_STATES) }
  scope :newly_designated,  ->{ any_in(aasm_state: NEWLY_DESIGNATED_STATES) }
  scope :linked,            ->{ any_in(aasm_state: LINKED_STATES) }
  scope :eligible,          ->{ any_in(aasm_state: ELIGIBLE_STATES) }
  scope :without_cobra,     ->{ not_in(aasm_state: COBRA_STATES) }
  scope :by_cobra,          ->{ any_in(aasm_state: COBRA_STATES) }
  scope :pending,           ->{ any_in(aasm_state: PENDING_STATES) }
  scope :eligible_without_term_pending, ->{ any_in(aasm_state: (ELIGIBLE_STATES - PENDING_STATES)) }

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

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def is_linked?
    LINKED_STATES.include?(aasm_state)
  end

  def is_eligible?
    ELIGIBLE_STATES.include?(aasm_state)
  end

  def allow_nil_ssn_updates_dependents
    census_dependents.each do |cd|
      if cd.ssn.blank?
        cd.unset(:encrypted_ssn)
      end
    end
  end

  def update_hbx_enrollment_effective_on_by_hired_on
    if employee_role.present? && hired_on != employee_role.hired_on
      employee_role.set(hired_on: hired_on)
      enrollments = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.open_enrollments rescue []
      enrollments.each do |enrollment|
        if hired_on > enrollment.effective_on
          effective_on = enrollment.benefit_group.effective_on_for(hired_on)
          enrollment.update_current(effective_on: effective_on)
        end
      end
    end
  end

  def suggested_cobra_effective_date
    return nil if self.employment_terminated_on.nil?
    self.employment_terminated_on.next_month.beginning_of_month
  end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(EmployerProfile)
    self.employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    @employer_profile = EmployerProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
  end

  # This performs employee summary count for waived and enrolled in the latest plan year
  def perform_employer_plan_year_count
    if plan_year = self.employer_profile.latest_plan_year
      plan_year.enrolled_summary = plan_year.total_enrolled_count
      plan_year.waived_summary = plan_year.waived_count
      plan_year.save!
    end
  end

  def employee_role=(new_employee_role)
    raise ArgumentError.new("expected EmployeeRole") unless new_employee_role.is_a? EmployeeRole
    return false unless self.may_link_employee_role?
    # Guard against linking employee roles with different employer/identifying information
    if (self.employer_profile_id == new_employee_role.employer_profile._id)
      self.employee_role_id = new_employee_role._id
      @employee_role = new_employee_role
      self.link_employee_role! if self.may_link_employee_role?
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

  def active_and_renewing_benefit_group_assignments
    result = []
    result << active_benefit_group_assignment if !active_benefit_group_assignment.nil? 
    result << renewal_benefit_group_assignment if !renewal_benefit_group_assignment.nil?
    result
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

  def generate_and_save_to_temp_folder
    begin
      url = Settings.checkbook_services.url
      event_kind = ApplicationEventKind.where(:event_name => 'out_of_pocker_url_notifier').first
      notice_trigger = event_kind.notice_triggers.first
      builder = notice_trigger.notice_builder.camelize.constantize.new(self, {
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
      builder = notice_trigger.notice_builder.camelize.constantize.new(self, {
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

  def terminate_employee_enrollments
    [self.active_benefit_group_assignment, self.renewal_benefit_group_assignment].compact.each do |assignment|
      enrollments = HbxEnrollment.find_enrollments_by_benefit_group_assignment(assignment)
      enrollments.each do |e|
        if e.effective_on > self.coverage_terminated_on
          e.cancel_coverage!(self.employment_terminated_on) if e.may_cancel_coverage?
        else
          if self.coverage_terminated_on < TimeKeeper.date_of_record
            e.terminate_coverage!(self.coverage_terminated_on) if e.may_terminate_coverage?
          else
            e.schedule_coverage_termination!(self.coverage_terminated_on) if e.may_schedule_coverage_termination?
          end
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

    terminate_employee_enrollments
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

  def assign_benefit_packages(benefit_group_id: nil, renewal_benefit_group_id: nil)
    if benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(benefit_group_id))
      
      if active_benefit_group_assignment.blank? || (active_benefit_group_assignment.benefit_group_id != benefit_group.id)
        find_or_create_benefit_group_assignment([benefit_group])
      end
    end

    if renewal_benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(renewal_benefit_group_id))
      if renewal_benefit_group_assignment.blank? || (renewal_benefit_group_assignment.benefit_group_id != benefit_group.id)
        add_renew_benefit_group_assignment(benefit_group)
      end
    end
  end

  def send_invite!
    if has_benefit_group_assignment?
      plan_year = active_benefit_group_assignment.benefit_group.plan_year
      if plan_year.employees_are_matchable?
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
      send_invite! if _id_changed?

      if employee_role.present?
        self.link_employee_role! if may_link_employee_role?
      else
        construct_employee_role_for_match_person if has_benefit_group_assignment?
      end
    end
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
    self.trigger_notices("employee_eligibility_notice")#sends EE eligibility notice to census employee
    return true
  end

  def newhire_enrollment_eligible?
    active_benefit_group_assignment.present? && active_benefit_group_assignment.initialized?
  end

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

    cobra_assignments = [active_benefit_group_assignment, renewal_benefit_group_assignment].compact
    hbxs = cobra_assignments.map(&:latest_hbx_enrollments_for_cobra).flatten.uniq rescue []

    hbxs.compact.each do |hbx|
      enrollment_cobra_factory = Factories::FamilyEnrollmentCloneFactory.new
      enrollment_cobra_factory.family = family
      enrollment_cobra_factory.census_employee = self
      enrollment_cobra_factory.enrollment = hbx
      enrollment_cobra_factory.clone_for_cobra
    end
  rescue => e
    logger.error(e)
  end

  class << self

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

    def advance_day(new_date)
      CensusEmployee.terminate_scheduled_census_employees
      CensusEmployee.rebase_newly_designated_employees
      CensusEmployee.terminate_future_scheduled_census_employees(new_date)
      CensusEmployee.initial_employee_open_enrollment_notice(new_date)
      CensusEmployee.census_employee_open_enrollment_reminder_notice(new_date)
    end

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

    def census_employee_open_enrollment_reminder_notice(date)
      organizations = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:aasm_state.in => ["enrolling", "renewing_enrolling"], :open_enrollment_end_on => date+2.days}})
      organizations.each do |org|
        plan_year = org.employer_profile.plan_years.where(:aasm_state.in => ["enrolling", "renewing_enrolling"]).first
        #exclude congressional employees
        next if plan_year.benefit_groups.any?{|bg| bg.is_congress?}
        census_employees = org.employer_profile.census_employees.non_terminated
        census_employees.each do |ce|
          begin
            #exclude new hires
            next if (ce.new_hire_enrollment_period.cover?(date) || ce.new_hire_enrollment_period.first > date)
            ShopNoticesNotifierJob.perform_later(ce.id.to_s, "employee_open_enrollment_reminder")
          rescue Exception => e
            (Rails.logger.error { "Unable to deliver open enrollment reminder notice to #{ce.full_name} due to #{e}" }) unless Rails.env.test?
          end
        end
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
    return true if current_user.try(:has_hbx_staff_role?)
    cobra_begin_date.present? && hired_on <= cobra_begin_date &&
      coverage_terminated_on && TimeKeeper.date_of_record <= (coverage_terminated_on + Settings.aca.shop_market.cobra_enrollment_period.months.months) &&
      coverage_terminated_on <= cobra_begin_date &&
      cobra_begin_date <= (coverage_terminated_on + Settings.aca.shop_market.cobra_enrollment_period.months.months)
  end

  def has_employee_role_linked?
    employee_role.present?
  end

  ##
  # This method is to verify whether roster employee is cobra eligible or not
  # = Rules for employee cobra eligibility
  #   * Employee must be in a terminated status
  #   * Must be a covered employee on the date of their employment termination
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
    return false if active_benefit_group_assignment.blank? || active_benefit_group_assignment.hbx_enrollment.blank?
    active_benefit_group_assignment.hbx_enrollment.is_cobra_status?
  end

  def need_update_hbx_enrollment_effective_on?
    !has_cobra_hbx_enrollment? && coverage_terminated_on.present?
  end

  def show_plan_end_date?
    is_inactive? && coverage_terminated_on.present?
  end

  def enrollments_for_display
    enrollments = []

    coverages_selected = lambda do |benefit_group_assignment|
      return [] if benefit_group_assignment.blank?
      coverages = benefit_group_assignment.active_and_waived_enrollments.reject{|e| e.external_enrollment }
      [coverages.detect{|c| c.coverage_kind == 'health'}, coverages.detect{|c| c.coverage_kind == 'dental'}]
    end

    enrollments += coverages_selected.call(active_benefit_group_assignment)
    enrollments += coverages_selected.call(renewal_benefit_group_assignment)
    enrollments.compact.uniq
  end

  private

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

  def notify_terminated
    notify(EMPLOYEE_TERMINATED_EVENT_NAME, { :census_employee_id => self.id } )
  end

  def notify_cobra_terminated
    notify(EMPLOYEE_COBRA_TERMINATED_EVENT_NAME, { :census_employee_id => self.id } )
  end
end

class CensusEmployeeError < StandardError; end
