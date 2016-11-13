class EmployerProfile
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  extend Acapi::Notifiers
  include StateTransitionPublisher

  embedded_in :organization
  attr_accessor :broker_role_id

  BINDER_PREMIUM_PAID_EVENT_NAME = "acapi.info.events.employer.binder_premium_paid"
  EMPLOYER_PROFILE_UPDATED_EVENT_NAME = "acapi.info.events.employer.updated"

  ACTIVE_STATES   = ["applicant", "registered", "eligible", "binder_paid", "enrolled"]
  INACTIVE_STATES = ["suspended", "ineligible"]

  PROFILE_SOURCE_KINDS  = ["self_serve", "conversion"]

  INVOICE_VIEW_INITIAL  = %w(published enrolling enrolled active suspended)
  INVOICE_VIEW_RENEWING = %w(renewing_published renewing_enrolling renewing_enrolled renewing_draft)


  field :entity_kind, type: String
  field :sic_code, type: String

  # Workflow attributes
  field :aasm_state, type: String, default: "applicant"


  field :profile_source, type: String, default: "self_serve"
  field :registered_on, type: Date, default: ->{ TimeKeeper.date_of_record }
  field :xml_transmitted_timestamp, type: DateTime

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  # TODO: make these relative to enrolling plan year
  # delegate :eligible_to_enroll_count, to: :enrolling_plan_year, allow_nil: true
  # delegate :non_business_owner_enrollment_count, to: :enrolling_plan_year, allow_nil: true
  # delegate :total_enrolled_count, to: :enrolling_plan_year, allow_nil: true
  # delegate :enrollment_ratio, to: :enrolling_plan_year, allow_nil: true
  # delegate :is_enrollment_valid?, to: :enrolling_plan_year, allow_nil: true
  # delegate :enrollment_errors, to: :enrolling_plan_year, allow_nil: true

  embeds_one  :inbox, as: :recipient, cascade_callbacks: true
  embeds_one  :employer_profile_account
  embeds_many :plan_years, cascade_callbacks: true, validate: true
  embeds_many :broker_agency_accounts, cascade_callbacks: true, validate: true
  embeds_many :general_agency_accounts, cascade_callbacks: true, validate: true

  embeds_many :workflow_state_transitions, as: :transitional
  embeds_many :documents, as: :documentable

  accepts_nested_attributes_for :plan_years, :inbox, :employer_profile_account, :broker_agency_accounts, :general_agency_accounts

  validates_presence_of :entity_kind

  validates :profile_source,
    inclusion: { in: EmployerProfile::PROFILE_SOURCE_KINDS },
    allow_blank: false

  validates :entity_kind,
    inclusion: { in: Organization::ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
    allow_blank: false

  after_initialize :build_nested_models
  after_save :save_associated_nested_models

  scope :active,      ->{ any_in(aasm_state: ACTIVE_STATES) }
  scope :inactive,    ->{ any_in(aasm_state: INACTIVE_STATES) }

  scope :all_renewing, ->{ Organization.all_employers_renewing }
  scope :all_with_next_month_effective_date,  ->{ Organization.all_employers_by_plan_year_start_on(TimeKeeper.date_of_record.end_of_month + 1.day) }

  alias_method :is_active?, :is_active

  # def self.all_with_next_month_effective_date
    # Organization.all_employers_by_plan_year_start_on(TimeKeeper.date_of_record.end_of_month + 1.day)
  # end

  def parent
    raise "undefined parent Organization" unless organization?
    organization
  end

  def census_employees
    CensusEmployee.find_by_employer_profile(self)
  end

  def benefit_group_assignments
    benefit_group_assignments = []
    self.census_employees.each do |census_employee|
      census_employee.benefit_group_assignments.each do |benefit_group_assignment|
        benefit_group_assignments << benefit_group_assignment
      end
    end
    return benefit_group_assignments
  end

  def covered_employee_roles
    covered_ee_ids = CensusEmployee.by_employer_profile_id(self.id).covered.only(:employee_role_id)
    EmployeeRole.ids_in(covered_ee_ids)
  end

  def owners #business owners
    staff_roles.select{|p| p.try(:employee_roles).try(:any?){|ee| ee.census_employee.is_business_owner? }}
  end

  def staff_roles #managing profile staff
    Person.staff_for_employer(self)
  end

  def match_employer(current_user)
    staff_roles.detect {|staff| staff.id == current_user.person_id}
  end

  def today=(new_date)
    raise ArgumentError.new("expected Date") unless new_date.is_a?(Date)
    @today = new_date
  end

  def today
    return @today if defined? @today
    @today = TimeKeeper.date_of_record
  end

  # for broker agency
  def hire_broker_agency(new_broker_agency, start_on = today)
    start_on = start_on.to_date.beginning_of_day
    if active_broker_agency_account.present?
      terminate_on = (start_on - 1.day).end_of_day
      fire_broker_agency(terminate_on)
    end
    broker_agency_accounts.build(broker_agency_profile: new_broker_agency, writing_agent_id: broker_role_id, start_on: start_on)
    @broker_agency_profile = new_broker_agency
  end

  def fire_broker_agency(terminate_on = today)
    return unless active_broker_agency_account
    active_broker_agency_account.end_on = terminate_on
    active_broker_agency_account.is_active = false
  end

  alias_method :broker_agency_profile=, :hire_broker_agency

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = active_broker_agency_account.broker_agency_profile if active_broker_agency_account.present?
  end

  def active_broker_agency_account
    return @active_broker_agency_account if defined? @active_broker_agency_account
    @active_broker_agency_account = broker_agency_accounts.detect { |account| account.is_active? }
  end

  def active_broker
    if active_broker_agency_account && active_broker_agency_account.writing_agent_id
      Person.where("broker_role._id" => BSON::ObjectId.from_string(active_broker_agency_account.writing_agent_id)).first
    end
  end

  def memoize_active_broker active_broker_memo
    return unless account = active_broker_agency_account
    if memo = active_broker_memo[account.broker_agency_profile_id] then return memo end
    active_broker_memo[account.broker_agency_profile.id] = active_broker
  end

  # for General Agency
  def hashed_active_general_agency_legal_name gaps
    return  unless account = active_general_agency_account
    gap = gaps.detect{|gap| gap.id == account.general_agency_profile_id}
    gap && gap.legal_name
  end

  def active_general_agency_legal_name
    if active_general_agency_account
      active_general_agency_account.legal_name
    end
  end

  def active_general_agency_account
    general_agency_accounts.active.first
  end

  def general_agency_profile
    return @general_agency_profile if defined? @general_agency_profile
    @general_agency_profile = active_general_agency_account.general_agency_profile if active_general_agency_account.present?
  end

  def hire_general_agency(new_general_agency, broker_role_id = nil, start_on = TimeKeeper.datetime_of_record)

    # commented out the start_on and terminate_on
    # which is same as broker calculation, However it will cause problem
    # start_on later than end_on
    #
    #start_on = start_on.to_date.beginning_of_day
    #if active_general_agency_account.present?
    #  terminate_on = (start_on - 1.day).end_of_day
    #  fire_general_agency!(terminate_on)
    #end
    fire_general_agency!(TimeKeeper.datetime_of_record) if active_general_agency_account.present?
    general_agency_accounts.build(general_agency_profile: new_general_agency, start_on: start_on, broker_role_id: broker_role_id)
    @general_agency_profile = new_general_agency
  end

  def fire_general_agency!(terminate_on = TimeKeeper.datetime_of_record)
    return if active_general_agency_account.blank?
    general_agency_accounts.active.update_all(aasm_state: "inactive", end_on: terminate_on)
  end
  alias_method :general_agency_profile=, :hire_general_agency

  def employee_roles
    return @employee_roles if defined? @employee_roles
    @employee_roles = EmployeeRole.find_by_employer_profile(self)
  end

  # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
  def roster_size
    return @roster_size if defined? @roster_size
    @roster_size = census_employees.active.size
  end

  def active_plan_year
    @active_plan_year if defined? @active_plan_year
    if plan_year = plan_years.published_plan_years_by_date(today).first
      @active_plan_year = plan_year
    end
  end

  def latest_plan_year
    plan_years.order_by(:'start_on'.desc).limit(1).only(:plan_years).first
  end

  def draft_plan_year
    plan_years.select{ |py| py.aasm_state == "draft" }
  end

  def published_plan_year
    plan_years.published.first
  end

  def show_plan_year
    renewing_published_plan_year || active_plan_year || published_plan_year
  end

  def plan_year_drafts
    plan_years.reduce([]) { |set, py| set << py if py.aasm_state == "draft" }
  end

  def is_coversion_employer?
    profile_source.to_s == 'conversion'
  end

  def find_plan_year_by_effective_date(target_date)
    plan_year = (plan_years.published + plan_years.renewing_published_state).detect do |py|
      (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(target_date)
    end

    if plan_year.present?
      (is_coversion_employer? && plan_year.coverage_period_contains?(registered_on)) ? plan_years.renewing_published_state.first : plan_year
    else
      plan_year
    end
  end

  def billing_plan_year(billing_date = nil)
    billing_report_date = billing_date || TimeKeeper.date_of_record.next_month
    plan_year = find_plan_year_by_effective_date(billing_report_date)

    if billing_date.blank?
      if plan_year.blank?
        if plan_year = (plan_years.published + plan_years.renewing_published_state).detect{|py| py.start_on > billing_report_date && py.open_enrollment_contains?(TimeKeeper.date_of_record) }
          billing_report_date = plan_year.start_on
        end
      end

      if plan_year.blank?
        if plan_year = find_plan_year_by_effective_date(TimeKeeper.date_of_record)
          billing_report_date = TimeKeeper.date_of_record
        end
      end

      if plan_year.blank?
        if plan_year = (plan_years.published + plan_years.renewing_published_state).detect{|py| py.start_on > billing_report_date }
          billing_report_date = plan_year.start_on
        end
      end
    end

    return plan_year, billing_report_date
  end

  def enrollments_for_billing(billing_date = nil)
    plan_year, billing_report_date = billing_plan_year(billing_date)
    hbx_enrollments = []

    if plan_year.present?
      hbx_enrollments = plan_year.hbx_enrollments_by_month(billing_report_date).compact
      # hbx_enrollments.reject!{|enrollment| !enrollment.census_employee.is_active?}
    end

    hbx_enrollments
  end

  def find_plan_year(id)
    plan_years.where(id: id).first
  end

  def renewing_published_plan_year
    plan_years.renewing_published_state.first
  end

  def renewing_plan_year
    plan_years.renewing.first
  end

  def can_transmit_xml?
    !self.renewing_plan_year.present? && !self.binder_paid?
  end

  def renewing_plan_year_drafts
    plan_years.reduce([]) { |set, py| set << py if py.aasm_state == "renewing_draft" }
  end

  def is_primary_office_local?
    organization.primary_office_location.address.state.to_s.downcase == Settings.aca.state_abbreviation.to_s.downcase
  end

  ## Class methods
  class << self

    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.employer_profile }
    end

    def all
      list_embedded Organization.exists(employer_profile: true).order_by([:legal_name]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("employer_profile._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile : nil
    rescue
      log("Can not find employer_profile with id #{id}", {:severity => "error"})
      nil
    end

    def find_by_fein(fein)
      organization = Organization.where(fein: fein).first
      organization.present? ? organization.employer_profile : nil
    end

    def find_by_broker_agency_profile(broker_agency_profile)
      raise ArgumentError.new("expected BrokerAgencyProfile") unless broker_agency_profile.is_a?(BrokerAgencyProfile)
      orgs = Organization.by_broker_agency_profile(broker_agency_profile.id)
      orgs.collect(&:employer_profile)
    end

    def find_by_general_agency_profile(general_agency_profile)
      raise ArgumentError.new("expected GeneralAgencyProfile") unless general_agency_profile.is_a?(GeneralAgencyProfile)
      orgs = Organization.by_general_agency_profile(general_agency_profile.id)
      orgs.collect(&:employer_profile)
    end

    def find_by_writing_agent(writing_agent)
      raise ArgumentError.new("expected BrokerRole") unless writing_agent.is_a?(BrokerRole)
      orgs = Organization.by_broker_role(writing_agent.id)
      orgs.collect(&:employer_profile)
    end

    def find_census_employee_by_person(person)
      return [] if person.ssn.blank? || person.dob.blank?
      CensusEmployee.matchable(person.ssn, person.dob)
    end

    def organizations_for_open_enrollment_begin(new_date)
      Organization.where(:"employer_profile.plan_years" =>
          { :$elemMatch => {
           :"open_enrollment_start_on".lte => new_date,
           :"open_enrollment_end_on".gte => new_date,
           :"aasm_state".in => ['published', 'renewing_published']
         }
      })
    end

    def organizations_for_open_enrollment_end(new_date)
      Organization.where(:"employer_profile.plan_years" =>
          { :$elemMatch => {
           :"open_enrollment_end_on".lt => new_date,
           :"start_on".gt => new_date,
           :"aasm_state".in => ['published', 'renewing_published', 'enrolling', 'renewing_enrolling']
         }
      })
    end

    def organizations_for_plan_year_begin(new_date)
      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"start_on".lte => new_date,
          :"end_on".gt => new_date,
          :"aasm_state".in => (PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE - ['active'])
        }
      })
    end

    def organizations_for_plan_year_end(new_date)
      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"end_on".lt => new_date,
          :"aasm_state".in => PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE
        }
      })
    end

    def organizations_eligible_for_renewal(new_date)
      months_prior_to_effective = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months * -1

      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"start_on" => (new_date + months_prior_to_effective.months) - 1.year,
          :"aasm_state".in => PlanYear::PUBLISHED
        }
      })
    end

    def organizations_for_force_publish(new_date)
      Organization.where({
        :'employer_profile.plan_years' =>
        { :$elemMatch => {
          :start_on => new_date.next_month.beginning_of_month,
          :aasm_state => 'renewing_draft'
          }}
      })
    end

    def advance_day(new_date)
      if !Rails.env.test?
        plan_year_renewal_factory = Factories::PlanYearRenewalFactory.new
        organizations_eligible_for_renewal(new_date).each do |organization|
          plan_year_renewal_factory.employer_profile = organization.employer_profile
          plan_year_renewal_factory.is_congress = false # TODO handle congress differently
          plan_year_renewal_factory.renew
        end

        open_enrollment_factory = Factories::EmployerOpenEnrollmentFactory.new
        open_enrollment_factory.date = new_date

        organizations_for_open_enrollment_begin(new_date).each do |organization|
          open_enrollment_factory.employer_profile = organization.employer_profile
          open_enrollment_factory.begin_open_enrollment
        end

        organizations_for_open_enrollment_end(new_date).each do |organization|
          open_enrollment_factory.employer_profile = organization.employer_profile
          open_enrollment_factory.end_open_enrollment
        end

        employer_enroll_factory = Factories::EmployerEnrollFactory.new
        employer_enroll_factory.date = new_date

        organizations_for_plan_year_begin(new_date).each do |organization|
          employer_enroll_factory.employer_profile = organization.employer_profile
          employer_enroll_factory.begin
        end

        organizations_for_plan_year_end(new_date).each do |organization|
          employer_enroll_factory.employer_profile = organization.employer_profile
          employer_enroll_factory.end
        end

        if new_date.day == Settings.aca.shop_market.renewal_application.force_publish_day_of_month
          organizations_for_force_publish(new_date).each do |organization|
            plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
            plan_year.force_publish!
          end
        end
      end

      # Employer activities that take place monthly - on first of month
      if new_date.day == 1
        orgs = Organization.exists(:"employer_profile.employer_profile_account._id" => true).not_in(:"employer_profile.employer_profile_account.aasm_state" => %w(canceled terminated))
        orgs.each do |org|
          org.employer_profile.employer_profile_account.advance_billing_period! if org.employer_profile.employer_profile_account.may_advance_billing_period?
          # if org.employer_profile.active_plan_year.present?
          #   Factories::EmployerRenewal(org.employer_profile) if org.employer_profile.today == (org.employer_profile.active_plan_year.end_on - 3.months + 1.day)
          # end
        end
      end

      # Find employers with events today and trigger their respective workflow states
      appeal_period = (Settings.
                          aca.
                          shop_market.
                          initial_application.
                          appeal_period_after_application_denial.
                          to_hash
                        )

      # Negate period value to query past date
      appeal_period.each {|k,v| appeal_period[k] = (v * -1) }

      ineligible_period = (Settings.
                              aca.
                              shop_market.
                              initial_application.
                              ineligible_period_after_application_denial.
                              to_hash
                            )

      # Negate period value to query past date
      ineligible_period.each {|k,v| ineligible_period[k] = (v * -1) }

      orgs = Organization.or(
        {:"employer_profile.plan_years.start_on" => new_date},
        {:"employer_profile.plan_years.end_on" => new_date - 1.day},
        {:"employer_profile.plan_years.open_enrollment_start_on" => new_date},
        {:"employer_profile.plan_years.open_enrollment_end_on" => new_date - 1.day},
        {:"employer_profile.workflow_state_transitions".elem_match => {
            "$and" => [
              {:transition_at.gte => (new_date.advance(ineligible_period).beginning_of_day )},
              {:transition_at.lte => (new_date.advance(ineligible_period).end_of_day)},
              {:to_state => "ineligible"}
            ]
          }
        }
      )

      orgs.each do |org|
        org.employer_profile.today = new_date
        org.employer_profile.advance_date! if org.employer_profile.may_advance_date?
        plan_year = org.employer_profile.published_plan_year
        plan_year.advance_date! if plan_year && plan_year.may_advance_date?
        plan_year
      end
    end
  end

  def revert_plan_year
    plan_year.revert
  end

  def default_benefit_group
    plan_year_with_default = plan_years.where("benefit_groups.default" => true).first
    return unless plan_year_with_default
    plan_year_with_default.benefit_groups.detect{|bg| bg.default }
  end

## TODO - anonymous shopping
# no fein required
# no SSNs, names, relationships, required
# build-in geographic rating and tobacco - set defaults

## TODO - Broker tools
# sample census profiles
# ability to create library of templates for employer profiles

  # Workflow for self service
  aasm do
    state :applicant, initial: true
    state :registered                 # Employer has submitted valid application
    state :eligible                   # Employer has completed enrollment and is eligible for coverage
    state :binder_paid, :after_enter => :notify_binder_paid
    state :enrolled                   # Employer has completed eligible enrollment, paid the binder payment and plan year has begun
  # state :lapsed                     # Employer benefit coverage has reached end of term without renewal
  state :suspended                  # Employer's benefit coverage has lapsed due to non-payment
    state :ineligible                 # Employer is unable to obtain coverage on the HBX per regulation or policy

    event :advance_date do
      transitions from: :ineligible, to: :applicant, :guard => :has_ineligible_period_expired?
    end

    event :application_accepted, :after => :record_transition do
      transitions from: [:registered], to: :registered
      transitions from: [:applicant, :ineligible], to: :registered
    end

    event :application_declined, :after => :record_transition do
      transitions from: :applicant, to: :ineligible
      transitions from: :ineligible, to: :ineligible
    end

    event :application_expired, :after => :record_transition do
      transitions from: :registered, to: :applicant
    end

    event :enrollment_ratified, :after => :record_transition do
      transitions from: [:registered, :ineligible], to: :eligible, :after => :initialize_account
    end

    event :enrollment_expired, :after => :record_transition do
      transitions from: :eligible, to: :applicant
    end

    event :binder_credited, :after => :record_transition do
      transitions from: :eligible, to: :binder_paid
    end

    event :binder_reversed, :after => :record_transition do
      transitions from: :binder_paid, to: :eligible
    end

    event :enroll_employer, :after => :record_transition do
      transitions from: :binder_paid, to: :enrolled
    end

    event :enrollment_denied, :after => :record_transition do
      transitions from: [:registered, :enrolled], to: :applicant
    end

    event :benefit_suspended, :after => :record_transition do
      transitions from: :enrolled, to: :suspended, :after => :suspend_benefit
    end

    event :employer_reinstated, :after => :record_transition do
      transitions from: :suspended, to: :enrolled
    end

    event :benefit_terminated, :after => :record_transition do
      transitions from: [:enrolled, :suspended], to: :applicant
    end

    event :benefit_canceled, :after => :record_transition do
      transitions from: :eligible, to: :applicant, :after => :cancel_benefit
    end

    # Admin capability to reset an Employer to applicant state
    event :revert_application, :after => :record_transition do
      transitions from: [:registered, :eligible, :ineligible, :suspended, :binder_paid, :enrolled], to: :applicant
    end

    event :force_enroll, :after => :record_transition do
      transitions from: [:applicant, :eligible, :registered], to: :enrolled
    end
  end

  after_update :broadcast_employer_update

  def broadcast_employer_update
    if previous_states.include?(:binder_paid) || (aasm_state.to_sym == :binder_paid)
      notify(EMPLOYER_PROFILE_UPDATED_EVENT_NAME, {:employer_id => self.hbx_id})
    end
  end

  def previous_states
    self.workflow_state_transitions.map(&:from_state).uniq.map(&:to_sym)
  end

  def within_open_enrollment_for?(t_date, effective_date)
    plan_years.any? do |py|
      py.open_enrollment_contains?(t_date) &&
        py.coverage_period_contains?(effective_date)
    end
  end

  def latest_workflow_state_transition
    workflow_state_transitions.order_by(:'transition_at'.desc).limit(1).first
  end

  def enrollment_ineligible_period_expired?
    if latest_workflow_state_transition.to_state == "ineligible"
      (latest_workflow_state_transition.transition_at.to_date.advance(Settings.
                                                                          aca.
                                                                          shop_market.
                                                                          initial_application.
                                                                          ineligible_period_after_application_denial.
                                                                          to_hash
                                                                        )
                                                                      ) <= TimeKeeper.date_of_record
    else
      true
    end
  end

  # def is_eligible_to_shop?
  #   registered? or published_plan_year.enrolling?
  # end

  def self.update_status_to_binder_paid(employer_profile_ids)
    employer_profile_ids.each do |id|
      empr = self.find(id)
      empr.update_attribute(:aasm_state, "binder_paid")
    end
  end

  def is_new_employer?
    !renewing_plan_year.present? #&& TimeKeeper.date_of_record > 10
  end

  def is_renewing_employer?
     renewing_plan_year.present? #&& TimeKeeper.date_of_record.day > 13
  end

  def has_next_month_plan_year?
    show_plan_year.present? && (show_plan_year.start_on == (TimeKeeper.date_of_record.next_month).beginning_of_month)
  end

  def is_eligible_to_enroll?
    published_plan_year.enrolling?
  end

  def notify_binder_paid
    notify(BINDER_PREMIUM_PAID_EVENT_NAME, {:employer_id => self.hbx_id})
  end

  def self.by_hbx_id(an_hbx_id)
    org = Organization.where(hbx_id: an_hbx_id, employer_profile: {"$exists" => true})
    return nil unless org.any?
    org.first.employer_profile
  end

  def is_conversion?
    self.profile_source == "conversion"
  end

private
  def has_ineligible_period_expired?
    ineligible? and (latest_workflow_state_transition.transition_at.to_date + 90.days <= TimeKeeper.date_of_record)
  end

  def cancel_benefit
    published_plan_year.cancel
  end

  def suspend_benefit
    published_plan_year.suspend
  end

  def terminate_benefit
    published_plan_year.terminate
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

  # TODO - fix premium amount
  def initialize_account
    if employer_profile_account.blank?
      self.build_employer_profile_account
      employer_profile_account.next_premium_due_on = (published_plan_year.start_on.last_month) + (Settings.aca.shop_market.binder_payment_due_on).days
      employer_profile_account.next_premium_amount = 100
      # census_employees.covered
      save
    end
  end

  def build_nested_models
    build_inbox if inbox.nil?
  end

  def save_associated_nested_models
  end

  def save_inbox
    welcome_subject = "Welcome to #{Settings.site.short_name}"
    welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    @inbox.save
    @inbox.messages.create(subject: welcome_subject, body: welcome_body)
  end

  def effective_date_expired?
    latest_plan_year.effective_date.beginning_of_day == (TimeKeeper.date_of_record.end_of_month + 1).beginning_of_day
  end

  def plan_year_publishable?
    published_plan_year.is_application_valid?
  end
end
