require 'ostruct'

class HbxEnrollment
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include HasFamilyMembers
  include AASM
  include MongoidSupport::AssociationProxies
  include Acapi::Notifiers
  extend Acapi::Notifiers
  include Mongoid::History::Trackable
  include BenefitSponsors::Concerns::Observable
  include BenefitSponsors::ModelEvents::HbxEnrollment

  belongs_to :household
  # Override attribute accessor as well
  # Migrate all the family ids to that
  # When we assign a household to the enrollment,
  # assign the family as well.
  # override the method where we do household_id == etc.
  belongs_to :family

  module AssociationExtensions
    def household=(hh)
      super(hh)
      if hh.family
        self.family = hh.family
      end
    end
  end

  prepend AssociationExtensions

  ENROLLMENT_CREATED_EVENT_NAME = "acapi.info.events.policy.created"
  ENROLLMENT_UPDATED_EVENT_NAME = "acapi.info.events.policy.updated"

  Authority           = [:open_enrollment]


  Kinds               = %w(individual employer_sponsored employer_sponsored_cobra coverall unassisted_qhp insurance_assisted_qhp streamlined_medicaid emergency_medicaid hcr_chip)

  ENROLLMENT_KINDS    = %w(open_enrollment special_enrollment)
  COVERAGE_KINDS      = %w(health dental)

  ENROLLED_STATUSES   = %w[coverage_selected transmitted_to_carrier coverage_enrolled coverage_termination_pending unverified coverage_reinstated].freeze
  SELECTED_AND_WAIVED = %w(coverage_selected inactive)
  TERMINATED_STATUSES = %w[coverage_terminated unverified coverage_expired].freeze
  CANCELED_STATUSES   = %w[coverage_canceled void].freeze # Void state enrollments are invalid enrollments. will be treated same as canceled.
  RENEWAL_STATUSES    = %w(auto_renewing renewing_coverage_selected renewing_transmitted_to_carrier renewing_coverage_enrolled
                              auto_renewing_contingent renewing_contingent_selected renewing_contingent_transmitted_to_carrier
                              renewing_contingent_enrolled
                            )
  WAIVED_STATUSES     = %w(inactive renewing_waived)

  ENROLLED_AND_RENEWAL_STATUSES = ENROLLED_STATUSES + RENEWAL_STATUSES

  ENROLLED_RENEWAL_WAIVED_STATUSES = ENROLLED_STATUSES + RENEWAL_STATUSES + WAIVED_STATUSES


  WAIVER_REASONS = [
      "I have coverage through spouse’s employer health plan",
      "I have coverage through parent’s employer health plan",
      "I have coverage through any other employer health plan",
      "I have coverage through an individual market health plan",
      "I have coverage through Medicare",
      "I have coverage through Tricare",
      "I have coverage through Medicaid"
  ]
  CAN_TERMINATE_ENROLLMENTS = %w[coverage_termination_pending coverage_selected auto_renewing renewing_coverage_selected unverified coverage_enrolled].freeze

  CAN_REINSTATE_AND_UPDATE_END_DATE = %w(coverage_termination_pending coverage_terminated)

  ENROLLMENT_TRAIN_STOPS_STEPS = {"coverage_selected" => 1, "transmitted_to_carrier" => 2, "coverage_enrolled" => 3,
                                  "auto_renewing" => 1, "renewing_coverage_selected" => 1, "renewing_transmitted_to_carrier" => 2, "renewing_coverage_enrolled" => 3}

  ENROLLMENT_TRAIN_STOPS_STEPS.default = 0

  # This field will be used to handle if the any of the enollment members are outstanding.
  field :is_any_enrollment_member_outstanding, type: Boolean, default: false

  field :coverage_household_id, type: String
  field :kind, type: String
  field :enrollment_kind, type: String, default: 'open_enrollment'
  field :coverage_kind, type: String, default: 'health'

  # FIXME: This unblocks people with legacy data where this field exists,
  #        preventing user registration as in #3394.  This is NOT a correct
  #        fix to that issue and it still needs to be addressed.
  field :elected_amount, type: Money, default: 0.0

  field :elected_premium_credit, type: Money, default: 0.0
  field :applied_premium_credit, type: Money, default: 0.0
  # TODO need to understand these two fields
  field :elected_aptc_pct, type: Float, default: 0.0
  field :applied_aptc_amount, type: Money, default: 0.0
  field :changing, type: Boolean, default: false

  field :effective_on, type: Date
  field :terminated_on, type: Date
  field :terminate_reason, type: String

  field :broker_agency_profile_id, type: BSON::ObjectId
  field :writing_agent_id, type: BSON::ObjectId
  field :employee_role_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_group_assignment_id, type: BSON::ObjectId
  field :hbx_id, type: String
  field :special_enrollment_period_id, type: BSON::ObjectId
  field :predecessor_enrollment_id, type: BSON::ObjectId
  field :enrollment_signature, type: String

  field :consumer_role_id, type: BSON::ObjectId
  field :resident_role_id, type: BSON::ObjectId
  # We will need to re-visit these names possibly, as we implement sponsored benefits.
  field :plan_id, type: BSON::ObjectId
  field :carrier_profile_id, type: BSON::ObjectId
  field :benefit_package_id, type: BSON::ObjectId
  field :benefit_coverage_period_id, type: BSON::ObjectId

  # Fields for new model
  field :benefit_sponsorship_id, type: BSON::ObjectId
  field :sponsored_benefit_package_id, type: BSON::ObjectId
  field :sponsored_benefit_id, type: BSON::ObjectId
  field :rating_area_id, type: BSON::ObjectId
  field :product_id, type: BSON::ObjectId
  field :issuer_profile_id, type: BSON::ObjectId

  field :original_application_type, type: String

  field :submitted_at, type: DateTime

  field :aasm_state, type: String
  field :aasm_state_date, type: Date    # Deprecated
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true
  field :waiver_reason, type: String
  field :published_to_bus_at, type: DateTime
  field :review_status, type: String, default: "incomplete"
  field :special_verification_period, type: DateTime
  field :termination_submitted_on, type: DateTime

  # Checkbook url
  field :checkbook_url , type: String

  # An external enrollment is one which we keep for recording purposes,
  # but did not originate with the exchange.  'External' enrollments
  # should not be transmitted to carriers nor reported in metrics.
  field :external_enrollment, type: Boolean, default: false

  track_history   :modifier_field_optional => true,
                  :on => [:kind,
                          :enrollment_kind,
                          :coverage_kind,
                          :effective_on,
                          :terminated_on,
                          :terminate_reason,
                          :aasm_state,
                          :is_active,
                          :waiver_reason,
                          :review_status,
                          :special_verification_period,
                          :termination_submitted_on],
                  :track_create  => true,    # track document creation, default is false
                  :track_update  => true,    # track document updates, default is true
                  :track_destroy => true     # track document destruction, default is false

  associated_with_one :benefit_group, :benefit_group_id, "BenefitGroup"
  associated_with_one :benefit_group_assignment, :benefit_group_assignment_id, "BenefitGroupAssignment"
  associated_with_one :employee_role, :employee_role_id, "EmployeeRole"
  associated_with_one :consumer_role, :consumer_role_id, "ConsumerRole"
  associated_with_one :resident_role, :resident_role_id, "ResidentRole"
  associated_with_one :broker, :writing_agent_id, "BrokerRole"

  delegate :total_premium, :total_employer_contribution, :total_employee_cost, to: :decorated_hbx_enrollment, allow_nil: true
  delegate :premium_for, to: :decorated_hbx_enrollment, allow_nil: true

  #indexes
  index({"household_id" => 1})
  index({"broker_agency_profile_id" => 1}, {sparse: true})
  index({"effective_on" => 1})
  index({"benefit_group_assignment_id" => 1})
  index({"benefit_group_id" => 1})

  index({"aasm_state" => 1,
         "created_at" => 1},
         {name: "state_and_created"})

    index({"kind" => 1,
         "aasm_state" => 1,
         "effective_on" => 1,
         "terminated_on" => 1
         },
         {name: "kind_and_state_and_created_and_terminated"})

  index({"is_any_enrollment_member_outstanding" => 1})
  index({"is_any_enrollment_member_outstanding" => 1,
       "aasm_state" => 1,
       "terminated_on" => 1,
       "family_id" =>  1
       },
       {name: "hbx_en_is_member_outstanding_and_aasm_state_and_terminated_on"})

  index({"kind" => 1,
       "aasm_state" => 1,
       "is_any_enrollment_member_outstanding" => 1,
       "effective_on" => 1,
       "family_id" => 1
       },
       {name: "kind_and_aasm_state_and_is_any_enrollment_member_outstanding_and_effective_on"})

  index({"kind" => 1,
         "aasm_state" => 1,
         "coverage_kind" => 1,
         "effective_on" => 1,
         "family_id" => 1
         },
         {name: "kind_and_state_and_coverage_kind_effective_date"})

  index({
    "sponsored_benefit_package_id" => 1,
    "coverage_kind" => 1,
    "kind" => 1,
    "family_id" => 1,
    "effective_on" => 1
  }, {name: "family_hbx_enrollments_by_package_lookup"})

  index({
    "sponsored_benefit_package_id" => 1,
    "sponsored_benefit_id" => 1,
    "effective_on" => 1,
    "submitted_at" => 1,
    "terminated_on" => 1,
    "employee_role_id" => 1,
    "aasm_state" => 1,
    "kind" => 1
  }, {name: "hbx_enrollment_sb_package_lookup"})

  index({
    "sponsored_benefit_id" => 1,
    "aasm_state" => 1,
    "effective_on" => 1,
    "submitted_at" => 1,
    "terminated_on" => 1,
    "employee_role_id" => 1
  }, {name: "hbx_enrollment_bp_enrolment_query_lookup"})

  index(
    {
      "is_active" => 1,
      "aasm_state" => 1,
      "family_id" => 1
    },
    {name: "hbx_enrollment_active_and_state_and_family"}
  )

  index(
    {
      "family_id" => 1,
      "external_enrollment" => 1,
      "aasm_state" => 1
    },
    {name: "hbx_enrollment_enrollments_for_display"}
  )

  index(
    {
      "family_id"  => 1,
      "aasm_state" => 1,
      "product_id" => 1
    },
    {name: "family_home_page_hidden_enrollments_lookup"}
  )

  index(
      {
          "benefit_group_id" => 1,
          "coverage_kind" => 1
      },
      {name: "enrollments_query_lookup_for_migration"}
  )
  index({ "benefit_sponsorship_id" => 1 })

  index({"plan_id" => 1}, { sparse: true })
  index({"product_id" => 1}, { sparse: true })
  index({"family_id" => 1})
  index({"writing_agent_id" => 1}, { sparse: true })
  index({"hbx_id" => 1})
  index({"kind" => 1})
  index({"submitted_at" => 1})
  index({"effective_on" => 1})
  index({"terminated_on" => 1}, { sparse: true })
  index({"applied_aptc_amount" => 1})


  scope :active,              ->{ where(is_active: true).where(:created_at.ne => nil) } # Depricated scope
  scope :open_enrollments,    ->{ where(enrollment_kind: "open_enrollment") }
  scope :special_enrollments, ->{ where(enrollment_kind: "special_enrollment") }
  scope :my_enrolled_plans,   ->{ where(:aasm_state.ne => "shopping", :plan_id.ne => nil ) } # a dummy plan has no plan id
  scope :by_created_datetime_range,  ->(start_at, end_at) { where(:created_at => { "$gte" => start_at, "$lte" => end_at }) }
  scope :by_submitted_datetime_range,  ->(start_at, end_at) { where(:submitted_at => { "$gte" => start_at, "$lte" => end_at }) }
  scope :by_submitted_after_datetime,  ->(start_at) { where(:submitted_at => { "$gte" => start_at} )}
  scope :by_updated_datetime_range, ->(start_at, end_at) { where(updated_at: { "$gte" => start_at, "$lte" => end_at }) }
  scope :by_effective_date_range, ->(start_on, end_on) { where(effective_on: { "$gte" => start_on, "$lte" => end_on }) }
  scope :current_year,        ->{ where(:effective_on.gte => TimeKeeper.date_of_record.beginning_of_year, :effective_on.lte => TimeKeeper.date_of_record.end_of_year) }
  scope :by_year,             ->(year) { where(effective_on: (Date.new(year)..Date.new(year).end_of_year)) }
  scope :by_hbx_id,            ->(hbx_id) { where(hbx_id: hbx_id) }
  scope :by_coverage_kind,    ->(kind) { where(coverage_kind: kind)}
  scope :by_health,           ->{where(coverage_kind: "health").order(effective_on: :desc)}
  scope :by_dental,           ->{where(coverage_kind: "dental").order(effective_on: :desc)}
  scope :by_kind,             ->(kind) { where(kind: kind)}
  scope :non_cobra,           ->{where(:"kind".ne => "employer_sponsored_cobra")}
  scope :with_aptc,           ->{ gt("applied_aptc_amount.cents": 0) }
  scope :without_aptc,        ->{lte("applied_aptc_amount.cents": 0) }
  scope :enrolled,            ->{ where(:aasm_state.in => ENROLLED_STATUSES ) }
  scope :non_enrolled,        ->{ where(:"aasm_state".nin => HbxEnrollment::ENROLLED_STATUSES) }
  scope :can_terminate,       ->{ where(:aasm_state.in =>  CAN_TERMINATE_ENROLLMENTS) }
  scope :enrolled_and_terminated,->{ where(:aasm_state.in => ENROLLED_STATUSES + TERMINATED_STATUSES) }
  scope :renewing,            ->{ where(:aasm_state.in => RENEWAL_STATUSES )}
  scope :enrolled_and_renewal, ->{where(:aasm_state.in => ENROLLED_AND_RENEWAL_STATUSES )}
  scope :enrolled_waived_and_renewing, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES + WAIVED_STATUSES)) }
  scope :enrolled_and_renewing, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES)) }
  scope :enrolled_and_renewing_and_shopping, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES + ['shopping'])) }
  scope :enrolled_and_renewing_and_expired, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES + ['coverage_expired'])) }
  scope :effective_asc,      -> { order(effective_on: :asc) }
  scope :effective_desc,      ->{ order(effective_on: :desc, submitted_at: :desc, coverage_kind: :desc) }
  scope :waived,              ->{ where(:aasm_state.in => WAIVED_STATUSES )}
  scope :expired,             ->{ where(:aasm_state => "coverage_expired")}
  scope :cancel_eligible,     ->{ where(:aasm_state.in => ["coverage_selected", "renewing_coverage_selected", "coverage_enrolled", "auto_renewing", "unverified"])}
  scope :changing,            ->{ where(changing: true) }
  scope :with_in,             ->(time_limit){ where(:created_at.gte => time_limit) }
  scope :shop_market,         ->{ where(:kind.in => ["employer_sponsored", "employer_sponsored_cobra"]) }
  scope :individual_market,   ->{ where(:kind.nin => ["employer_sponsored", "employer_sponsored_cobra"]) }
  scope :verification_needed, ->{ where(:is_any_enrollment_member_outstanding => true, :aasm_state.in => ENROLLED_STATUSES).or({:terminated_on => nil }, {:terminated_on.gt => TimeKeeper.date_of_record}).order(created_at: :desc) }
  scope :outstanding_enrollments, ->{ individual_market.enrolled.current_year.where(:is_any_enrollment_member_outstanding => true) }

  scope :canceled, -> { where(:aasm_state.in => CANCELED_STATUSES) }
  scope :family_home_page_hidden_enrollments, ->(family) do
    where(
      :family_id => family.id,
      :aasm_state => "coverage_canceled",
      :product_id.nin => [nil]
    ).order(
      effective_on: :desc, submitted_at: :desc, coverage_kind: :desc
    )
  end
  #scope :terminated, -> { where(:aasm_state.in => TERMINATED_STATUSES, :terminated_on.gte => TimeKeeper.date_of_record.beginning_of_day) }
  scope :terminated, -> { where(:aasm_state.in => TERMINATED_STATUSES) }
  scope :canceled_and_terminated, -> { where(:aasm_state.in => (CANCELED_STATUSES + TERMINATED_STATUSES)) }
  scope :enrolled_and_waived, -> { any_of([enrolled.selector, waived.selector]).order(created_at: :desc) }
  scope :enrolled_waived_terminated_and_expired, -> { any_of([enrolled.selector, waived.selector, terminated.selector, expired.selector]).order(created_at: :desc) }
  scope :show_enrollments, -> { any_of([enrolled.selector, renewing.selector, terminated.selector, canceled.selector, waived.selector]) }
  scope :show_enrollments_sans_canceled, -> { any_of([enrolled.selector, renewing.selector, terminated.selector, waived.selector]).order(created_at: :desc) }
  scope :enrollments_for_cobra, -> { where(:aasm_state.in => ['coverage_terminated', 'coverage_termination_pending', 'auto_renewing']).order(created_at: :desc) }
  scope :with_plan, -> { where(:plan_id.ne => nil) }
  scope :with_product, -> { where(:product_id.ne => nil) }
  scope :coverage_selected_and_waived, -> {where(:aasm_state.in => SELECTED_AND_WAIVED).order(created_at: :desc)}
  scope :non_terminated, -> { where(:aasm_state.ne => 'coverage_terminated') }
  scope :non_external, -> { where(:external_enrollment => false) }
  scope :non_expired_and_non_terminated,  -> { any_of([enrolled.selector, renewing.selector, waived.selector]).order(created_at: :desc) }
  scope :by_benefit_sponsorship,   -> (benefit_sponsorship) { where(:benefit_sponsorship_id => benefit_sponsorship.id) }
  scope :by_benefit_package,       -> (benefit_package) { where(:sponsored_benefit_package_id => benefit_package.id) }
  scope :by_enrollment_period,     -> (enrollment_period) { where(:effective_on.gte => enrollment_period.min, :effective_on.lte => enrollment_period.max) }

  scope :by_effective_period,      ->(effective_period) { where(
                                                          :"effective_on".gte => effective_period.min,
                                                          :"effective_on".lte => effective_period.max
                                                        )}
  scope :by_terminated_period,      ->(term_date) { where(
                                                          :"terminated_on".gte => term_date,
                                                          :"terminated_on".lte => term_date
                                                        )}
  scope :by_benefit_application_and_sponsored_benefit,  ->(benefit_application, sponsored_benefit, end_date) do
    where(
      :"sponsored_benefit_id" => sponsored_benefit._id,
      :"aasm_state".in => (ENROLLED_STATUSES + RENEWAL_STATUSES + TERMINATED_STATUSES),
      :"effective_on".lte => end_date,
      :"effective_on".gte => benefit_application.effective_period.min
    )
  end
  scope :enrollments_for_monthly_report_sep_scope, lambda { |start_date, end_date, family_id|
    where(family_id: family_id).special_enrollments.individual_market.show_enrollments_sans_canceled.where(
      :"created_at" => {:"$gte" => start_date, :"$lt" => end_date}
    )
  }
  # Rewritten from family scopes
  scope :enrolled_statuses, -> { where(:"aasm_state".in => ENROLLED_STATUSES) }
  scope :by_writing_agent_id, ->(broker_id) { where(writing_agent_id: broker_id)}
  scope :by_benefit_group_ids, ->(benefit_group_ids) { where(:"benefit_group_id".in => benefit_group_ids) }
  scope :by_benefit_sponsorship_id, ->(benefit_sponsorship_id) { where(benefit_sponsorship_id: benefit_sponsorship_id) }
  scope :verified, ->{ where(is_any_enrollment_member_outstanding: true, :"review_status" => "ready") }
  scope :by_unverified, -> { where(is_any_enrollment_member_outstanding: true)}
  scope :partially_verified, -> { where(is_any_enrollment_member_outstanding: true, :"review_status" => "ready") }
  scope :not_verified, -> { where(is_any_enrollment_member_outstanding: true, :"review_status" => "in review") }
  scope :reset_verifications, -> { where(is_any_enrollment_member_outstanding: true, :"review_status" => "incomplete") }
  scope :verification_outstanding, -> do
    where(
      is_any_enrollment_member_outstanding: true,
      effective_on: { :"$gte" => TimeKeeper.date_of_record.beginning_of_year, :"$lte" =>  TimeKeeper.date_of_record.end_of_year }
    )
  end

  embeds_many :workflow_state_transitions, as: :transitional

  belongs_to :benefit_sponsorship, class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship", optional: true

  embeds_many :hbx_enrollment_members
  accepts_nested_attributes_for :hbx_enrollment_members, reject_if: :all_blank, allow_destroy: true

  embeds_many :comments, as: :commentable, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :kind,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: Kinds, message: "%{value} is not a valid enrollment type"}

  validates :enrollment_kind,
            allow_blank: false,
            inclusion: {
                in: ENROLLMENT_KINDS,
                message: "%{value} is not a valid enrollment kind"
            }

  validates :coverage_kind,
            allow_blank: false,
            inclusion: {
                in: COVERAGE_KINDS,
                message: "%{value} is not a valid coverage type"
            }

  add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_enrollment_events]

  before_save :generate_hbx_id, :set_submitted_at, :check_for_subscriber, :set_is_any_enrollment_member_outstanding
  after_save :check_created_at
  after_save :notify_on_save

  # def max_aptc
  #   family&.active_household&.latest_active_tax_household_with_year(effective_on.year)&.total_aptc_available_amount_for_enrollment(self)
  # end

  # This method checks to see if there is at least one subscriber in the hbx_enrollment_members nested document.
  # If not, it assigns it to the oldest person.
  def check_for_subscriber
    if hbx_enrollment_members.map { |x| x.is_subscriber ? 1 : 0 }.max == 0
      new_is_subscriber_true = hbx_enrollment_members.min_by { |hbx_member| hbx_member.person.dob }
      new_is_subscriber_true.is_subscriber = true
    end
  end

  def generate_hbx_signature
    if self.subscriber
      self.enrollment_signature = Digest::MD5.hexdigest(self.subscriber.applicant_id.to_s)
    elsif self.subscriber.nil?
      self.enrollment_signature =  Digest::MD5.hexdigest(applicant_ids.sort.map(&:to_s).join)
    end
  end

  def benefit_group
    return @benefit_group if defined? @benefit_group
    return nil if benefit_group_id.blank?
    @benefit_group = BenefitGroup.find(self.benefit_group_id)
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event
    )
  end

  def renew_benefit(new_benefit_package, result_reporter = ::BenefitSponsors::BenefitPackages::SilentRenewalReporter.new)
    begin
      enrollment = BenefitSponsors::Factories::EnrollmentRenewalFactory.call(self, new_benefit_package)
      if enrollment.save
        assignment = self.employee_role.census_employee.benefit_group_assignment_by_package(enrollment.sponsored_benefit_package_id)
        assignment.update_attributes(hbx_enrollment_id: enrollment.id)
      else
        result_reporter.report_enrollment_save_renewal_failure(self, self.errors)
      end
      enrollment
    rescue Exception => e
      result_reporter.report_enrollment_renewal_exception(self, e)
    end
  end

  # checks possibility of coverage renewal for ivl enrollments
  def can_renew_coverage?(new_effective_on)
    return false unless is_ivl_by_kind?

    enrollments = family.active_household.hbx_enrollments.where(
      {:coverage_kind => coverage_kind,
       :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing', 'renewing_coverage_selected']),
       :effective_on.gte => new_effective_on,
       :kind => kind}
    )
    return true if enrollments.empty?

    enrollments.none?{|e| subscriber.blank? || subscriber.hbx_id == e.subscriber.hbx_id }
  end

  def has_at_least_one_aptc_eligible_member?(year)
    tax_households = family.active_household.tax_households.tax_household_with_year(year).active_tax_household
    return false if tax_households.blank?
    tax_households.first.tax_household_members.any?(&:is_ia_eligible?)
  end

  class << self

    # terminate all Enrollments scheduled for termination
    def terminate_scheduled_enrollments(as_of_date = TimeKeeper.date_of_record)
      HbxEnrollment.where(:aasm_state => 'coverage_termination_pending', :terminated_on.lt => as_of_date).each do |hbx_enrollment|
        hbx_enrollment.terminate_coverage!(hbx_enrollment.terminated_on)
      rescue StandardError => e
        Rails.logger.error { "Error terminating scheduled enrollment hbx_id - #{hbx_enrollment.hbx_id} due to #{e.backtrace}" }
      end
    end

    def enrollments_for_display(family_id)
      HbxEnrollment.collection.aggregate(
        [
          {'$match' => {
            'aasm_state' => {'$nin' => ['void', "coverage_canceled"]},
            'external_enrollment' => {'$ne' => true},
            'family_id' => family_id,
          }},
          {"$project" => {"_id": 1}}
        ],
        :allow_disk_use => true
      ).to_a
    end

    def by_hbx_id(policy_hbx_id)
      self.where(hbx_id: policy_hbx_id)
      # families = Family.with_enrollment_hbx_id(policy_hbx_id)
      # households = families.flat_map(&:households)
      # households.flat_map(&:hbx_enrollments).select do |hbxe|
      #   hbxe.hbx_id == policy_hbx_id
      # end
    end

    def process_verification_reminders(date_passed)
      people_to_check = Person.where("consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding")
      families = Family.where("family_members.person_id" => {"$in" => people_to_check.map(&:_id)})

      # TODO handle multiple enrollments with different special enrolment period dates
      families.each do |family|
        [10, 25, 50, 65].each do |reminder_days|
          enrollment = family.enrollments.order(created_at: :desc).select{|e| e.currently_active? || e.future_active?}.first

          if enrollment.special_verification_period.present? && enrollment.special_verification_period.strftime('%m/%d/%Y') == (date_passed + (95 - reminder_days).days).strftime('%m/%d/%Y')
            consumer_role = family.primary_applicant.person.consumer_role
            begin
              case reminder_days
                when 10
                  consumer_role.first_verifications_reminder
                when 25
                  consumer_role.second_verifications_reminder
                when 50
                  consumer_role.third_verifications_reminder
                when 65
                  consumer_role.fourth_verifications_reminder
              end
            rescue Exception => e
              Rails.logger.error e.to_s
            end
          end
        end
      end
    end

    def advance_day(new_date)
      # process_verification_reminders(new_date - 1.day)

      # families_with_contingent_enrollments.each do |family|
      #   enrollment = family.enrollments.where('aasm_state' => 'enrolled_contingent').order(created_at: :desc).to_a.first
      #   consumer_role = family.primary_applicant.person.consumer_role
      #   if enrollment.present? && consumer_role.present? && consumer_role.verifications_outstanding?
      #     case (TimeKeeper.date_of_record - enrollment.created_at).to_i
      #     when 10
      #       consumer_role.first_verifications_reminder
      #     when 25
      #       consumer_role.second_verifications_reminder
      #     when 50
      #       consumer_role.third_verifications_reminder
      #     when 65
      #       consumer_role.fourth_verifications_reminder
      #     else
      #     end
      #   end
      # end

      HbxEnrollment.terminate_scheduled_enrollments
    end

    def update_individual_eligibilities_for(consumer_role)
      found_families = Family.find_all_by_person(consumer_role.person)
      found_families.each do |ff|
        ff.households.each do |hh|
          hh.hbx_enrollments.active.each do |he|
            he.evaluate_individual_market_eligiblity
          end
        end
      end
    end
  end

  def evaluate_individual_market_eligiblity
    eligibility_ruleset = ::RuleSet::HbxEnrollment::IndividualMarketVerification.new(self)
    if eligibility_ruleset.applicable?
      if self.is_any_enrollment_member_outstanding != eligibility_ruleset.determine_next_state[0]
        self.update_attributes!(is_any_enrollment_member_outstanding: eligibility_ruleset.determine_next_state[0])
      end

      if eligibility_ruleset.determine_next_state[1] != :do_nothing
        self.send(eligibility_ruleset.determine_next_state[1])
      end
    end
  end

  def coverage_kind
    self[:coverage_kind] || product.kind
  end

  def benefit_package_name
    if is_shop? && benefit_group
      benefit_group.title
    end
  end

  PREDECESSOR_ID_INTRODUCTION_DATE = Date.new(2017,8,1)

  def parent_enrollment
    return HbxEnrollment.find(predecessor_enrollment_id) if predecessor_enrollment_id.present?
    return nil if effective_on >= PREDECESSOR_ID_INTRODUCTION_DATE
    return nil if created_at.present? && created_at >= PREDECESSOR_ID_INTRODUCTION_DATE
    return nil if is_shop? && (effective_on == sponsored_benefit_package.start_on)
    search_for_predecessor
  end

  def search_for_predecessor
    possible_enrollments = family.hbx_enrollments.where({effective_on: {"$lt" => effective_on},
                                                         sponsored_benefit_package_id: sponsored_benefit_package_id,
                                                         coverage_kind: coverage_kind,
                                                         kind: kind,
                                                         external_enrollment: {'$ne' => true},
                                                         product_id: {"$ne" => nil},
                                                         employee_role_id: employee_role_id,
                                                         aasm_state: {"$nin": ["shopping", "coverage_canceled", "void", "inactive", "renewing_waived"]}})
    possible_enrollments.select do |pe|
      pe.terminated_on && (pe.terminated_on == (effective_on - 1.day))
    end.first
  end

  def census_employee
    if employee_role.present?
      employee_role.census_employee
    elsif benefit_group_assignment.present? && benefit_group_assignment.census_employee.present?
      benefit_group_assignment.census_employee
    else
      nil
    end
  end

  def market_name
    if is_shop?
      'Employer Sponsored'
    else
      'Individual'
    end
  end

  def is_cobra_status?
    kind.to_s == 'employer_sponsored_cobra'
  end

  def future_enrollment_termination_date
    return "" unless coverage_termination_pending?
    employee_role && employee_role.census_employee && employee_role.census_employee.coverage_terminated_on
  end

  def benefit_sponsored?
    sponsored_benefit_package_id.present? && sponsored_benefit_package.present?
  end

  def affected_by_verifications_made_today?
    return false if shopping?
    return true if terminated_on.blank?
    terminated_on >= TimeKeeper.date_of_record
  end

  def active_during?(date)
    return false if ["shopping", "coverage_canceled", "void"].include?(aasm_state.to_s)
    return false if effective_on.blank?
    if terminated_on.present?
      (effective_on..terminated_on).include?(date)
    else
      logical_end = self.sponsored_benefit_package.end_on
      (effective_on..logical_end).include?(date)
    end
  end

  def is_active?
    self.is_active
  end

  def currently_active?
    return false if shopping?
    return false unless (effective_on <= TimeKeeper.date_of_record)
    return true if terminated_on.blank?
    terminated_on >= TimeKeeper.date_of_record
  end

  def future_active?
    return false if shopping?
    return false unless (effective_on > TimeKeeper.date_of_record)
    return true if terminated_on.blank?
    terminated_on >= effective_on
  end

  def cobra_future_active?
    is_cobra_status? && future_active?
  end

  def validate_for_cobra_eligiblity(role, current_user)
    if self.is_shop?
      if role.present? && role.is_cobra_status?
        census_employee = role.census_employee
        self.kind = 'employer_sponsored_cobra'
        self.effective_on = census_employee.cobra_begin_date if census_employee.cobra_begin_date > self.effective_on
        # removing 6 months eligibility rule for cobra EE during shopping, however the 6months rules needs to be validated during cobra initiation for CE.
        # if census_employee.coverage_terminated_on.present? && !census_employee.have_valid_date_for_cobra?(current_user)
        #   raise "You may not enroll for cobra after #{Settings.aca.shop_market.cobra_enrollment_period.months} months later of coverage terminated."
        # end
      end
    end
  end

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_policy_id) if hbx_id.blank?
  end

  def propogate_cancel
    # SHOP: Implement if we have requirement from buiness, event need to happen after cancel in shop.
    # IVL: cancel renewals on cancelling active coverage.
    return if is_shop?
    ::EnrollRegistry[:cancel_renewals_for_term] { {hbx_enrollment: self} }
  end

  def propogate_terminate(term_date = TimeKeeper.date_of_record.end_of_month)
    if terminated_on.present? && term_date < terminated_on
      self.terminated_on = term_date
    else
      self.terminated_on ||= term_date
    end

    if benefit_group_assignment
      benefit_group_assignment.end_benefit(terminated_on)
      benefit_group_assignment.save
    end

    if should_transmit_update?
      notify(ENROLLMENT_UPDATED_EVENT_NAME, {policy_id: self.hbx_id})
    end

    ::EnrollRegistry[:cancel_renewals_for_term] { {hbx_enrollment: self} }
  end

  def propogate_waiver
    return false unless is_shop? # there is no concept of waiver in ivl case

    if coverage_kind == 'health' && benefit_group_assignment.present?
      benefit_group_assignment.waive_coverage! if benefit_group_assignment.may_waive_coverage?
    end

    true
  end

  def propagate_renewal
    if is_shop? && coverage_kind == 'health'
      benefit_group_assignment.renew_coverage! if benefit_group_assignment.may_renew_coverage?
    end
  end

  def construct_waiver_enrollment(waiver_reason = nil)
    qle = family.is_under_special_enrollment_period? && (family.earliest_effective_shop_sep.present? || family.earliest_effective_fehb_sep.present?)
    coverage_hh = employee_role.person.primary_family.active_household.immediate_family_coverage_household
    waived_enrollment = coverage_hh.household.new_hbx_enrollment_from(employee_role: employee_role, coverage_household: coverage_hh, benefit_package: sponsored_benefit_package, benefit_group_assignment: benefit_group_assignment, qle: qle)
    waived_enrollment.coverage_kind = coverage_kind
    waived_enrollment.enrollment_kind = (qle ? 'special_enrollment' : 'open_enrollment')
    waived_enrollment.kind = 'employer_sponsored_cobra' if employee_role.present? && employee_role.is_cobra_status?
    waived_enrollment.terminate_reason = terminate_reason if terminate_reason
    waived_enrollment.waiver_reason = waiver_reason if waiver_reason
    waived_enrollment.predecessor_enrollment_id = _id
    waived_enrollment.generate_hbx_signature
    waived_enrollment.submitted_at = TimeKeeper.datetime_of_record
    waived_enrollment.household.reload if waived_enrollment.save!

    waived_enrollment
  end

  def term_existing_shop_enrollments
    benefit_application = sponsored_benefit_package.benefit_application
    terminating_benefit_package_ids = benefit_application.benefit_packages.pluck(:id)

    # cancel or term previous year enrollments if waiver is created under renewal application
    # cancel or term renewal application enrollments if waiver created under the active application
    if benefit_application.is_renewing?
      if (effective_on == sponsored_benefit_package.start_on) && employer_profile
        predecessor_benefit_application = employer_profile.benefit_applications.published_benefit_applications_by_date(effective_on.prev_day).first
        terminating_benefit_package_ids += predecessor_benefit_application.benefit_packages.pluck(:id) if predecessor_benefit_application.present?
      end
    else
      future_benefit_application = employer_profile.find_plan_year_by_effective_date(benefit_application.effective_period.max.next_day)
      terminating_benefit_package_ids += future_benefit_application.benefit_packages.pluck(:id) if future_benefit_application.present?
    end

    terminating_enrollments = household.hbx_enrollments.where({:sponsored_benefit_package_id.in => terminating_benefit_package_ids,
                                                               :coverage_kind => coverage_kind}).enrolled_and_renewing_and_expired

    renewing_enrollments = household.hbx_enrollments.where({:sponsored_benefit_package_id.in => terminating_benefit_package_ids,
                                                            :coverage_kind => coverage_kind}).renewing

    # waive only renewal enrollments if waives coverage after clicking "make changes" on renewing coverage
    aasm_state = parent_enrollment.aasm_state if parent_enrollment
    enrollments = if WAIVED_STATUSES.include?(aasm_state)
                    parent_enrollment.to_a
                  elsif is_open_enrollment? && renewing_enrollments.present?
                    update(predecessor_enrollment_id: renewing_enrollments.first.id)
                    (renewing_enrollments + terminating_enrollments).uniq
                  else
                    terminating_enrollments
                  end

    enrollments.each do |enrollment|
      coverage_end_date = if benefit_application.is_renewing? && benefit_application.start_on == effective_on && predecessor_benefit_application.effective_period.cover?(enrollment.effective_on)
                            enrollment.sponsored_benefit_package.end_on
                          else
                            family.terminate_date_for_shop_by_enrollment(enrollment)
                          end
      term_or_cancel_enrollment(enrollment, coverage_end_date)
    end
  end

  def set_predecessor_if_exists
    predecessor_benefit_packages = [sponsored_benefit_package.id]

    if effective_on == sponsored_benefit_package.start_on && sponsored_benefit_package.benefit_application.is_renewing?
      if employer_profile
        predecessor_benefit_application = employer_profile.benefit_applications.published_benefit_applications_by_date(effective_on.prev_day).first
        predecessor_benefit_packages = predecessor_benefit_application.benefit_packages.pluck(:id) if predecessor_benefit_application
      end
    end

    predecessor_enrollment = household.hbx_enrollments.where({:sponsored_benefit_package_id.in => predecessor_benefit_packages,
                                                              :aasm_state.in => ENROLLED_STATUSES,
                                                              :coverage_kind => coverage_kind}).first

    update(predecessor_enrollment_id: predecessor_enrollment.id) if predecessor_enrollment.present?
  end

  def waive_enrollment
    return unless is_shop? && may_waive_coverage?
    waive_coverage!
    set_predecessor_if_exists if predecessor_enrollment_id.blank?
    term_existing_shop_enrollments
  end

  def terminate_enrollment(coverage_end_date = TimeKeeper.date_of_record.end_of_month, terminate_reason)
    term_or_cancel_enrollment(self, coverage_end_date, terminate_reason)

    return unless is_shop? && (coverage_termination_pending? || coverage_terminated? || coverage_canceled?)

    return if waiver_enrollment_present?

    waiver = construct_waiver_enrollment
    waiver.waive_coverage! if waiver.may_waive_coverage?
  end

  def term_or_cancel_enrollment(enrollment, coverage_end_date, term_reason = nil)
    if enrollment.effective_on >= coverage_end_date
      enrollment.cancel_coverage! if enrollment.may_cancel_coverage? # cancel coverage if enrollment is future effective
    elsif coverage_end_date >= TimeKeeper.date_of_record && enrollment.is_shop?
      enrollment.schedule_coverage_termination!(coverage_end_date) if enrollment.may_schedule_coverage_termination?
    elsif enrollment.may_terminate_coverage?
      enrollment.terminate_coverage!(coverage_end_date)
    end
    enrollment.update(terminate_reason: term_reason, termination_submitted_on: TimeKeeper.datetime_of_record) if term_reason.present?
  end

  def should_term_or_cancel_ivl
    if self.effective_on > TimeKeeper.date_of_record
      'cancel'
    elsif (self.effective_on <= TimeKeeper.date_of_record || self.may_terminate_coverage?)
      'terminate'
    end
  end

  def waiver_enrollment_present?
    return false if employee_role.blank?

    family = employee_role.person.primary_family
    return false if family.blank?

    family.enrollments.where({:predecessor_enrollment_id => id, :aasm_state.in => WAIVED_STATUSES}).present?
  end

  def terminate_coverage_with(termination_date)
    # IVL enrollments go automatically to coverage_terminated
    if termination_date >= TimeKeeper.datetime_of_record && is_shop?
      schedule_coverage_termination!(termination_date) if may_schedule_coverage_termination?
    else
      if may_terminate_coverage?
        update_attributes!(terminated_on: termination_date)
        terminate_coverage!
      end
    end
  end

  def update_existing_shop_coverage
    return if parent_enrollment.blank?
    return unless benefit_sponsorship_id == parent_enrollment.benefit_sponsorship_id # Allows EE to shop under a different employer.

    if parent_enrollment.effective_on >= effective_on
      parent_enrollment.cancel_coverage! if parent_enrollment.may_cancel_coverage?
    else
      parent_enrollment.terminate_coverage_with(effective_on.prev_day)
    end
  end

  def propagate_selection
    return unless [:coverage_selected, :renewing_coverage_selected].include?(aasm.to_state)

    Operations::ExecuteProductSelectionEffects.call(
      Entities::ProductSelection.new(
        {
          :enrollment => self,
          :product => self.product,
          :family => self.family
        }
      )
    )
  end

  def handle_coverage_selection
    callback_context = { :hbx_enrollment => self }
    HandleCoverageSelected.call(callback_context)
  end

  def update_renewal_coverage(options = nil)  # rubocop:disable Metrics/CyclomaticComplexity
    return if options.is_a?(Hash) && options[:skip_renewal_coverage_update]
    return unless is_shop?
    return if census_employee&.is_employee_in_term_pending?

    enrollment_benefit_application = sponsored_benefit_package.benefit_application

    return unless enrollment_benefit_application.active?
    return unless census_employee&.renewal_benefit_group_assignment

    successor_benefit_package = census_employee.renewal_benefit_group_assignment.benefit_package
    successor_application = successor_benefit_package.benefit_application if successor_benefit_package

    return unless successor_application&.is_submitted?
    return unless enrollment_benefit_application.successors.include?(successor_application)

    passive_renewals_under(successor_application).each{|en| en.cancel_coverage! if en.may_cancel_coverage? }
    renew_benefit(successor_benefit_package) if active_renewals_under(successor_application).blank? && successor_application.coverage_renewable? && non_inactive_transition? && non_terminated_enrollment?
  end

  def non_inactive_transition?
    !(aasm.from_state == :inactive && aasm.to_state == :inactive)
  end

  def non_terminated_enrollment?
    ['coverage_terminated', 'coverage_termination_pending'].exclude?(aasm_state)
  end

  def renewal_enrollments(successor_application)
    HbxEnrollment.where({
      :sponsored_benefit_package_id.in => successor_application.benefit_packages.pluck(:_id),
      :coverage_kind => coverage_kind,
      :kind => kind,
      :family_id => family_id,
      :effective_on => successor_application.start_on
    })
  end

  def active_renewals_under(successor_application)
    renewal_enrollments(successor_application).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['inactive'])
  end

  def passive_renewals_under(successor_application)
    renewal_enrollments(successor_application).where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES + ['renewing_waived'])
  end

  def should_transmit_update?
    !self.published_to_bus_at.blank?
  end

  def is_coverage_waived?
    inactive? || renewing_waived?
  end

  def is_shop?
    ['employer_sponsored', 'employer_sponsored_cobra'].include?(kind)
  end

  def is_coverall?
    kind == "coverall"
  end

  def is_shop_sep?
    is_shop? && is_special_enrollment?
  end

  def is_open_enrollment?
    enrollment_kind == "open_enrollment"
  end

  def is_special_enrollment?
    enrollment_kind == "special_enrollment"
  end

  def terminate_benefit(submitted_on = TimeKeeper.date_of_record)
    if is_shop?
      self.terminated_on = benefit_group.termination_effective_on_for(submitted_on)
    else
      bcp = BenefitCoveragePeriod.find_by_date(effective_on)
      self.terminated_on = bcp.termination_effective_on_for(submitted_on)
    end
    terminate_coverage!
  end

  # def benefit_package
  #   is_shop? ? benefit_group : benefit_sponsor.benefit_coverage_period.each {}
  # end
  #

  def benefit_sponsor
    is_shop? ? employer_profile : HbxProfile.current_hbx.benefit_sponsorship
  end

  def transmit_shop_enrollment!
    if !consumer_role.present?
      if !is_shop_sep?
        notify(ENROLLMENT_CREATED_EVENT_NAME, {policy_id: self.hbx_id})
        self.published_to_bus_at = Time.now
        self.save!
      end
    end
  end

  def household
    family.households.where(id: self.household_id).first
  end

  def subscriber
    hbx_enrollment_members.detect(&:is_subscriber)
  end

  def applicant_ids
    hbx_enrollment_members.pluck(:applicant_id)
  end

  def employer_profile
    if self.employee_role.present?
      self.employee_role.employer_profile
    elsif !self.sponsored_benefit_package_id.blank?
      self.sponsored_benefit_package.sponsor_profile
    else
      nil
    end
  end

  def fehb_profile
    employer_profile.is_a?(BenefitSponsors::Organizations::FehbEmployerProfile) ? employer_profile : nil
  end

  def mid_year_plan_change_notice
    if self.census_employee.present?
      begin
        if (self.enrollment_kind != "open_enrollment" || self.census_employee.new_hire_enrollment_period.present?)
          if self.benefit_group.is_congress
            ShopNoticesNotifierJob.perform_later(self.employer_profile.id.to_s, "ee_mid_year_plan_change_congressional_notice", hbx_enrollment: self.hbx_id.to_s)
          else
            ShopNoticesNotifierJob.perform_later(self.employer_profile.id.to_s, "ee_mid_year_plan_change_non_congressional_notice", hbx_enrollment: self.hbx_id.to_s)
          end
        end
      rescue Exception => e
        Rails.logger.error {"Unable to send employee mid year plan change notice to census_employee - #{census_employee.id} due to #{e.backtrace}"}
      end
    end
  end

  def <=>(other)
    other_members = other.hbx_enrollment_members # - other.terminated_members
    [product.hios_id, effective_on, hbx_enrollment_members.sort_by(&:hbx_id)] <=> [other.product.hios_id, other.effective_on, other_members.sort_by(&:hbx_id)]
  end

  # This performs employee summary count for waived and enrolled in the latest plan year
  def perform_employer_plan_year_count
    if is_shop?
      return if self.employer_profile.nil? || self.employer_profile.latest_plan_year.nil?
      plan_year = self.employer_profile.latest_plan_year
      plan_year.enrolled_summary = plan_year.total_enrolled_count
      plan_year.waived_summary = plan_year.waived_count
      plan_year.save!
    end
  end

  def enroll_step
    ENROLLMENT_TRAIN_STOPS_STEPS[self.aasm_state]
  end

  def special_enrollment_period
    return @special_enrollment_period if defined? @special_enrollment_period
    return nil if special_enrollment_period_id.blank?
    @special_enrollment_period = family.special_enrollment_periods.detect {|sep| sep.id == special_enrollment_period_id}
  end

  def plan=(new_plan)
    raise ArgumentError.new("expected Plan") unless new_plan.is_a? Plan
    self.plan_id = new_plan._id
    self.carrier_profile_id = new_plan.carrier_profile_id #new_plan.carrier_profile_id
    @plan = new_plan
  end

  def plan
    return @plan if defined? @plan
    @plan = Plan.find(self.plan_id) unless plan_id.blank?
  end

  def benefit_sponsorship
    return @benefit_sponsorship if defined? @benefit_sponsorship
    @benefit_sponsorship = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(benefit_sponsorship_id)
  end

  def benefit_sponsorship=(benefit_sponsorship)
    raise ArgumentError.new("expected BenefitSponsors::BenefitSponsorships::BenefitSponsorship") unless benefit_sponsorship.is_a? ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship
    self.benefit_sponsorship_id = benefit_sponsorship._id
    @benefit_sponsorship = benefit_sponsorship
  end

  def sponsored_benefit_package
    return @sponsored_benefit_package if defined? @sponsored_benefit_package
    @sponsored_benefit_package = ::BenefitSponsors::BenefitPackages::BenefitPackage.find(sponsored_benefit_package_id) if sponsored_benefit_package_id.present?
  end

  def sponsored_benefit_package=(benefit_package)
    raise ArgumentError.new("expected BenefitSponsors::BenefitPackages::BenefitPackage") unless benefit_package.is_a? ::BenefitSponsors::BenefitPackages::BenefitPackage
    self.sponsored_benefit_package_id = benefit_package._id
    @sponsored_benefit_package = benefit_package
  end

  def sponsored_benefit
    return @sponsored_benefit if defined? @sponsored_benefit
    @sponsored_benefit = sponsored_benefit_package.sponsored_benefits.detect{ |sb| sb.id == sponsored_benefit_id }
  end

  def sponsored_benefit=(sponsored_benefit)
    raise ArgumentError.new("expected BenefitSponsors::SponsoredBenefits::SponsoredBenefit") unless sponsored_benefit.is_a? ::BenefitSponsors::SponsoredBenefits::SponsoredBenefit
    self.sponsored_benefit_id = sponsored_benefit._id
    @sponsored_benefit = sponsored_benefit
  end

  def rating_area
    return @rating_area if defined? @rating_area
    @rating_area = ::BenefitMarkets::Locations::RatingArea.find(self.rating_area_id)
  end

  def rating_area=(rating_area)
    raise ArgumentError.new("expected BenefitMarkets::Locations::RatingArea") unless rating_area.is_a? ::BenefitMarkets::Locations::RatingArea
    self.rating_area_id = rating_area._id
    @rating_area = rating_area
  end

  def product=(new_product)
    if new_product.blank?
      self.product_id = nil
      self.issuer_profile_id = nil
      @product = nil
      return
    end
    raise ArgumentError.new("expected product") unless new_product.kind_of?(BenefitMarkets::Products::Product)
    self.product_id = new_product._id
    self.issuer_profile_id = new_product.issuer_profile_id
    @product = new_product
  end

  def product
    return @product if defined? @product
    @product = BenefitMarkets::Products::Product.find(self.product_id) unless product_id.blank?
  end

  def set_coverage_termination_date(coverage_terminated_on=TimeKeeper.date_of_record)
    self.terminated_on = coverage_terminated_on
  end

  def select_applicable_broker_account(broker_accounts)
    last_broker_before_purchase = broker_accounts.select do |baa|
      (baa.start_on < self.time_of_purchase)# &&
    end.sort_by(&:start_on).last
    return nil if last_broker_before_purchase.nil?
    if  ((last_broker_before_purchase.end_on.blank?) || (last_broker_before_purchase.end_on >= self.time_of_purchase))
      last_broker_before_purchase
    else
      nil
    end
  end

  def shop_broker_agency_account
    return nil if self.employer_profile.blank?
    return nil if self.employer_profile.broker_agency_accounts.unscoped.empty?
    select_applicable_broker_account(self.employer_profile.broker_agency_accounts.unscoped)
  end

  def broker_agency_account
    return shop_broker_agency_account if is_shop?
    return nil if family.broker_agency_accounts.unscoped.empty?
    select_applicable_broker_account(family.broker_agency_accounts.unscoped)
  end

  def time_of_purchase
    return submitted_at unless submitted_at.blank?
    updated_at
  end

  def has_broker_agency_profile?
    broker_agency_profile_id.present?
  end

  def can_waive_enrollment?(on_date = ::TimeKeeper.date_of_record)
    return false unless is_shop?
    return false unless may_waive_coverage?
    return true if self.sponsored_benefit_package.open_enrollment_contains?(on_date)
    # TODO: Get a method for is_under_special enrollment period that will
    # check based on a given time.
    family.is_under_special_enrollment_period?
  end

  def can_make_changes?
    return false if coverage_canceled?
    if is_shop?
      can_make_changes_for_shop_enrollment?
    else
      can_make_changes_for_ivl_enrollment?
    end
  end

  def can_make_changes_for_shop_enrollment?
    return false if sponsored_benefit_package.blank?
    return true if open_enrollment_period_available?
    return true if special_enrollment_period_available?
    return true if new_hire_enrollment_period_available?
    false
  end

  def can_make_changes_for_ivl_enrollment?
    return true if ENROLLED_AND_RENEWAL_STATUSES.include?(aasm_state)
    false
  end

  def open_enrollment_period_available?
    return false if coverage_expired?
    sponsored_benefit_package.open_enrollment_period.cover?(TimeKeeper.date_of_record)
  end

  def special_enrollment_period_available?
    shop_sep = family.earliest_effective_shop_sep
    return false unless shop_sep
    sponsored_benefit_package.effective_period.cover?(shop_sep.effective_on)
  end

  def new_hire_enrollment_period_available?
    return false if employee_role.blank?
    sponsored_benefit_package.effective_on_for(employee_role.hired_on) > sponsored_benefit_package.start_on
  end

  def can_complete_shopping?(options = {})
    household.family.is_eligible_to_enroll?(qle: options[:qle])
  end

  def humanized_dependent_summary
    hbx_enrollment_members.count - 1
  end

  def humanized_members_summary
    hbx_enrollment_members.count{|member| member.covered? }
  end

  def phone_number
    if plan.present?
      phone = plan.try(:carrier_profile).try(:organization).try(:primary_office_location).try(:phone)
      "#{phone.try(:area_code)}#{phone.try(:number)}"
    else
      ""
    end
  end

  def rebuild_members_by_coverage_household(coverage_household:)
    applicant_ids = hbx_enrollment_members.pluck(:applicant_id)
    coverage_household.coverage_household_members.each do |coverage_member|
      next if applicant_ids.include? coverage_member.family_member_id
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = self.effective_on
      enrollment_member.coverage_start_on = self.effective_on
      self.hbx_enrollment_members << enrollment_member
    end
    self
  end

  def coverage_period_date_range
    is_shop? ?
        benefit_group.plan_year.start_on..benefit_group.plan_year.start_on :
        benefit_coverage_period.start_on..benefit_coverage_period.end_on
  end

  def coverage_year
    year = if self.is_shop?
             sponsored_benefit_package.benefit_application.start_on.year
           else
             product.try(:active_year) || effective_on.year
           end
  end

  def update_hbx_enrollment_members_premium(decorated_plan)
    return if decorated_plan.blank? && hbx_enrollment_members.blank?

    hbx_enrollment_members.each do |member|
      # TODO: update applied_aptc_amount error like hbx_enrollment
      member.update_attributes!(applied_aptc_amount: decorated_plan.aptc_amount(member))
    end
  end

  def earlier_effective_sep_by_market_kind
    if is_shop?
      fehb_profile ? family.earliest_effective_fehb_sep : family.earliest_effective_shop_sep
    else
      family.earliest_effective_ivl_sep
    end
  end

  def set_special_enrollment_period
    if is_special_enrollment? && special_enrollment_period_id.blank?
      update_attributes!(special_enrollment_period_id: earlier_effective_sep_by_market_kind.id) if earlier_effective_sep_by_market_kind
    end
  end

  def is_an_existing_plan?(new_plan)
    if is_shop?
      family.currently_enrolled_product_ids(self).include?(new_plan.id)
    else
      family.currently_enrolled_products(self).select{ |plan| plan.is_same_plan_by_hios_id_and_active_year?(new_plan) }.present?
    end
  end

  def reset_dates_on_previously_covered_members(new_plan=nil)
    new_plan ||= product

    if is_an_existing_plan?(new_plan)
      plan_selection = PlanSelection.new(self, product)
      self.hbx_enrollment_members = plan_selection.same_plan_enrollment.hbx_enrollment_members
    end
  end

  def display_make_changes_for_ivl?
    return true if is_shop?

    benefit_sponsorship = HbxProfile.current_hbx.try(:benefit_sponsorship)
    benefit_coverage_period = benefit_sponsorship.current_benefit_period
    is_ivl_by_kind? && (family.latest_ivl_sep&.start_on&.year == effective_on.year ||
      (family.is_under_ivl_open_enrollment? && effective_on >= benefit_coverage_period.start_on))
  end

  def build_plan_premium(qhp_plan: nil, elected_aptc: false, tax_household: nil, apply_aptc: nil)
    qhp_plan ||= product

    if self.is_shop?
      if benefit_group.is_congress
        PlanCostDecoratorCongress.new(qhp_plan, self, benefit_group)
      elsif self.composite_rated? && (!qhp_plan.dental?)
        CompositeRatedPlanCostDecorator.new(qhp_plan, benefit_group, self.composite_rating_tier, is_cobra_status?)
      else
        reference_plan = (coverage_kind == "health") ? benefit_group.reference_plan : benefit_group.dental_reference_plan
        PlanCostDecorator.new(qhp_plan, self, benefit_group, reference_plan)
      end
    else
      if apply_aptc
        UnassistedPlanCostDecorator.new(qhp_plan, self, elected_aptc, tax_household)
      else
        UnassistedPlanCostDecorator.new(qhp_plan, self)
      end
    end
  end

  def decorated_elected_plans(coverage_kind, market=nil)
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship

    if enrollment_kind == 'special_enrollment' && family.is_under_special_enrollment_period?
      special_enrollment_id = family.current_special_enrollment_periods.first.id
      benefit_coverage_period = benefit_sponsorship.benefit_coverage_period_by_effective_date(effective_on)
    else
      benefit_coverage_period = benefit_sponsorship.current_benefit_period
    end

    tax_household = (market.present? && market == 'individual') ? household.latest_active_tax_household_with_year(effective_on.year) : nil
    elected_plans = benefit_coverage_period.elected_plans_by_enrollment_members(hbx_enrollment_members, coverage_kind, tax_household, market)
    elected_plans.collect {|plan| UnassistedPlanCostDecorator.new(plan, self)}
  end

  def calculate_costs_for_plans(elected_plans)
    elected_plans.collect {|plan| UnassistedPlanCostDecorator.new(plan, self)}
  end

  # FIXME: not sure what this is or if it should be removed - Sean
  def inactive_related_hbxs
    hbxs = if employee_role.present?
             household.hbx_enrollments.ne(id: id).select do |hbx|
               hbx.employee_role.present? and hbx.employee_role.employer_profile_id == employee_role.employer_profile_id
             end
             #elsif consumer_role_id.present?
             #  #FIXME when have more than one individual hbx
             #  household.hbx_enrollments.ne(id: id).select do |hbx|
             #    hbx.consumer_role_id.present? and hbx.consumer_role_id == consumer_role_id
             #  end
           else
             []
           end
    household.hbx_enrollments.any_in(id: hbxs.map(&:_id)).update_all(is_active: false)
  end

  def inactive_pre_hbx(pre_hbx_id)
    return if pre_hbx_id.blank?
    pre_hbx = HbxEnrollment.find(pre_hbx_id)
    if self.consumer_role.present? && self.consumer_role_id == pre_hbx.consumer_role_id
      pre_hbx.update_attributes!(is_active: false, changing: false)
    end
  end

  def self.family_canceled_enrollments(family)
    canceled_enrollments = HbxEnrollment.family_home_page_hidden_enrollments(family)
    canceled_enrollments.reject{|enrollment| enrollment.is_shop? && enrollment.sponsored_benefit_id.blank? }
  end

  # TODO: Fix this to properly respect mulitiple possible employee roles for the same employer
  #       This should probably be done by comparing the hired_on date with todays date.
  #       Also needs to ignore any that were already terminated before a certain date.
  def self.calculate_start_date_from(employee_role, coverage_household, benefit_group)
    benefit_group.effective_on_for(employee_role.hired_on)
  end

  def self.calculate_effective_on_from(market_kind: 'shop', qle: false, family: nil, employee_role: nil, benefit_group: nil, benefit_sponsorship: HbxProfile.current_hbx.benefit_sponsorship)
    return nil if family.blank?

    case market_kind
      when 'shop', 'fehb'
        if qle && family.is_under_special_enrollment_period? && benefit_group.present?
          family.current_sep.effective_on
        else
          # we always have benefit group unless QLE gives an effective date before plan year start on
          # return employee_role.census_employee.coverage_effective_on if benefit_group.blank?
          # benefit_group.effective_on_for(employee_role.hired_on)
          employee_role.census_employee.coverage_effective_on
        end
      when 'individual'
        if qle && family.is_under_special_enrollment_period?
          family.current_sep.effective_on
        else
          benefit_sponsorship.current_benefit_period.earliest_effective_date
        end
      when 'coverall'
        if qle && family.is_under_special_enrollment_period?
          family.current_sep.effective_on
        else
          benefit_sponsorship.current_benefit_period.earliest_effective_date
        end
    end
  rescue => e
    log(e.message, {:severity => "error"})
    nil
  end

  def self.effective_date_for_enrollment(employee_role, hbx_enrollment, qle)

    if employee_role.census_employee.new_hire_enrollment_period.min > TimeKeeper.date_of_record
      raise "You're not yet eligible under your employer-sponsored benefits. Please return on #{employee_role.census_employee.new_hire_enrollment_period.min.strftime("%m/%d/%Y")} to enroll for coverage."
    end

    if employee_role.can_enroll_as_new_hire?
      employee_role.coverage_effective_on(qle: qle)
    elsif qle
      hbx_enrollment.earlier_effective_sep_by_market_kind.effective_on
    else
      active_plan_year = employee_role.employer_profile.show_plan_year

      if active_plan_year.blank?
        raise "Unable to find employer-sponsored benefits."
      end

      if !employee_role.is_under_open_enrollment?
        raise "You may not enroll unless it’s open enrollment or you’re eligible for a special enrollment period."
      end

      employee_role.employer_profile.show_plan_year.start_on
    end
  end

  def self.employee_current_benefit_group(employee_role, hbx_enrollment, qle)
    effective_date = effective_date_for_enrollment(employee_role, hbx_enrollment, qle)
    plan_year = employee_role.employer_profile.find_plan_year_by_effective_date(effective_date)

    if plan_year.blank?
      raise "Unable to find employer-sponsored benefits for enrollment year #{effective_date.year}"
    end

    if plan_year.open_enrollment_start_on > TimeKeeper.date_of_record
      raise "Open enrollment for your employer-sponsored benefits not yet started. Please return on #{plan_year.open_enrollment_start_on.strftime("%m/%d/%Y")} to enroll for coverage."
    end

    census_employee = employee_role.census_employee
    benefit_group_assignment = plan_year.is_renewing? ?
        census_employee.renewal_benefit_group_assignment : (plan_year.aasm_state == "expired" && qle) ? census_employee.benefit_group_assignments.order_by(:'created_at'.desc).detect { |bga| bga.plan_year.aasm_state == "expired"} : census_employee.active_benefit_group_assignment

    if benefit_group_assignment.blank? || benefit_group_assignment.plan_year != plan_year
      raise "Unable to find an active or renewing benefit group assignment for enrollment year #{effective_date.year}"
    end

    return benefit_group_assignment.benefit_group, benefit_group_assignment
  end

  def self.new_from(employee_role: nil, coverage_household: nil, benefit_group: nil, benefit_group_assignment: nil, consumer_role: nil, benefit_package: nil, qle: false, submitted_at: nil, resident_role: nil, external_enrollment: false, coverage_start: nil, opt_effective_on: nil)
    enrollment = HbxEnrollment.new
    enrollment.household = coverage_household.household
    enrollment.family = coverage_household.household.family
    enrollment.submitted_at = submitted_at

    case
      when employee_role.present?
        enrollment.kind = "employer_sponsored"
        enrollment.employee_role = employee_role

        if benefit_group.blank? || benefit_group_assignment.blank?
          benefit_group, benefit_group_assignment = employee_current_benefit_group(employee_role, enrollment, qle)
        end
        if qle && employee_role.coverage_effective_on(qle: qle) > employee_role.person.primary_family.current_sep.effective_on
          raise "You are attempting to purchase coverage through Qualifying Life Event prior to your eligibility date. Please contact your Employer for assistance. You are eligible for employer benefits from #{employee_role.coverage_effective_on(qle: qle)} "
        end

        if qle && enrollment.family.is_under_special_enrollment_period?
          if opt_effective_on.present?
            enrollment.effective_on = opt_effective_on
          elsif enrollment.plan_year_check(employee_role)
            enrollment.effective_on =  enrollment.family.current_sep.effective_on
          else
            enrollment.effective_on = [enrollment.family.current_sep.effective_on, benefit_group.start_on].max
          end
          enrollment.enrollment_kind = "special_enrollment"
        else
          if external_enrollment && coverage_start.present?
            enrollment.effective_on = coverage_start
          else
            enrollment.effective_on = calculate_start_date_from(employee_role, coverage_household, benefit_group)
          end
          enrollment.enrollment_kind = "open_enrollment"
        end

        enrollment.benefit_group_id = benefit_group.id
        enrollment.benefit_group_assignment_id = benefit_group_assignment.id
        enrollment.sponsored_benefit_package_id = benefit_package.id if benefit_package
      when consumer_role.present?
        enrollment.consumer_role = consumer_role
        enrollment.kind = "individual"
        enrollment.benefit_package_id = benefit_package.try(:id)
        benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
        if qle && enrollment.family.is_under_special_enrollment_period?
          enrollment.effective_on = opt_effective_on.present? ? opt_effective_on : enrollment.family.current_sep.effective_on
          enrollment.enrollment_kind = "special_enrollment"
        elsif enrollment.family.is_under_ivl_open_enrollment?
          enrollment.effective_on = benefit_sponsorship.current_benefit_period.earliest_effective_date
          enrollment.enrollment_kind = "open_enrollment"
        else
          raise "You may not enroll unless it’s open enrollment or you’re eligible for a special enrollment period."
        end
      when resident_role.present?
        enrollment.kind = "coverall"
        enrollment.resident_role = resident_role
        enrollment.benefit_package_id = benefit_package.try(:id)
        benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship

        if qle && enrollment.family.is_under_special_enrollment_period?
          enrollment.effective_on = opt_effective_on.present? ? opt_effective_on : enrollment.family.current_sep.effective_on
          enrollment.enrollment_kind = "special_enrollment"
        elsif enrollment.family.is_under_ivl_open_enrollment?
          enrollment.effective_on = benefit_sponsorship.current_benefit_period.earliest_effective_date
          enrollment.enrollment_kind = "open_enrollment"
        else
          raise "You may not enroll unless it’s open enrollment or you’re eligible for a special enrollment period."
        end
      else
        raise "either employee_role or consumer_role is required" unless resident_role.present?
    end
    coverage_household.coverage_household_members.each do |coverage_member|
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = enrollment.effective_on
      enrollment_member.coverage_start_on = enrollment.effective_on
      enrollment.hbx_enrollment_members << enrollment_member
    end

    enrollment
  end

  def self.create_from(employee_role: nil, coverage_household: nil, benefit_group: nil, benefit_group_assignment: nil, consumer_role: nil, benefit_package: nil)
    enrollment = self.new_from(
        employee_role: employee_role,
        coverage_household: coverage_household,
        benefit_group: benefit_group,
        benefit_group_assignment: benefit_group_assignment,
        consumer_role: consumer_role,
        benefit_package: benefit_package
    )
    enrollment.save
    enrollment
  end

  def covered_members_first_names
    hbx_enrollment_members.inject([]) do |names, member|
      names << member.person.first_name
    end
  end

  def can_terminate_coverage?
    may_terminate_coverage? and effective_on <= TimeKeeper.date_of_record
  end

  def can_be_reinstated?
    return false if is_shop? && benefit_sponsorship.blank?
    return false unless self.coverage_terminated? || self.coverage_termination_pending?
    return false if is_shop? && employee_role.is_cobra_status? && self.kind == "employer_sponsored"
    return false if is_shop? && !employee_role.is_cobra_status? && self.kind == 'employer_sponsored_cobra'
    is_shop? && benefit_sponsorship.benefit_applications.published_benefit_applications_by_date(terminated_on.next_day).present? ||is_ivl_by_kind? && is_effective_in_current_year?
  end

  def has_active_or_term_exists_for_reinstated_date?
    enrollment_kind = is_shop? ? ['employer_sponsored', 'employer_sponsored_cobra'] : (Kinds - ["employer_sponsored", "employer_sponsored_cobra"])
    HbxEnrollment.where({:family_id => self.family_id,
                         :kind.in => enrollment_kind,
                         :effective_on.gte => self.terminated_on.next_day,
                         :coverage_kind => self.coverage_kind,
                         :employee_role_id => self.employee_role_id,
                         :aasm_state.in => (ENROLLED_AND_RENEWAL_STATUSES + CAN_REINSTATE_AND_UPDATE_END_DATE)}).any?
  end

  def notify_of_coverage_start(publish_to_carrier)
    config = Rails.application.config.acapi
    notify(
        "acapi.info.events.hbx_enrollment.coverage_selected",
        {
            :reply_to => "#{config.hbx_id}.#{config.environment_name}.q.glue.enrollment_event_batch_handler",
            "hbx_enrollment_id" => self.hbx_id,
            "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#initial",
            "is_trading_partner_publishable" => publish_to_carrier
        }
    )
  end

  def reinstate(edi: false)
    return false unless can_be_reinstated?
    return false if has_active_or_term_exists_for_reinstated_date?
    reinstate_enrollment = Enrollments::Replicator::Reinstatement.new(self, terminated_on.next_day).build

    if self.is_shop?
      census_employee = benefit_group_assignment.census_employee
      census_employee.reinstate_employment if census_employee.can_be_reinstated?
    end

    if reinstate_enrollment.may_reinstate_coverage?
      reinstate_enrollment.reinstate_coverage!
      # Move reinstated enrollment to "coverage selected" status
      reinstate_enrollment.begin_coverage! if reinstate_enrollment.may_begin_coverage?
      # Move reinstated enrollment to "coverage enrolled" status if coverage begins
      reinstate_enrollment.begin_coverage! if reinstate_enrollment.may_begin_coverage? && self.effective_on <= TimeKeeper.date_of_record
      reinstate_enrollment.notify_of_coverage_start(edi)
    end
    reinstate_enrollment
  end

  def self.find_by_benefit_groups(benefit_groups = [])
    id_list = benefit_groups.collect(&:_id).uniq
    HbxEnrollment.where(:benefit_group_id.in => id_list).enrolled_and_renewing.to_a
  end

  def self.all_enrollments_under_benefit_application(benefit_application)
    id_list = benefit_application.benefit_packages.collect(&:_id).uniq
    benefit_application.active_and_cobra_enrolled_families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in => id_list).enrolled_waived_and_renewing.to_a
    end
  end

  def self.enrolled_shop_health_benefit_group_ids(benefit_group_assignment_list)
    return [] if benefit_group_assignment_list.empty?
    enrollment_list = []
    families = Family.where("households.hbx_enrollments.benefit_group_assignment_id" => {"$in" => benefit_group_assignment_list})
    families.each do |family|
      family.households.each do |household|
        household.hbx_enrollments.show_enrollments_sans_canceled.shop_market.by_coverage_kind("health").each do |enrollment|
          enrollment_list << enrollment if (benefit_group_assignment_list.include?(enrollment.benefit_group_assignment_id))
        end
      end
    end rescue ''
    enrollment_list.map(&:benefit_group_assignment_id).uniq
  end

  def self.find_enrollments_by_benefit_group_assignment(benefit_group_assignment)
    return [] if benefit_group_assignment.blank?
    benefit_group_assignment_id = benefit_group_assignment.id
    HbxEnrollment.where(:"benefit_group_assignment_id" => benefit_group_assignment_id).show_enrollments_sans_canceled.non_terminated.shop_market.to_a
  end

  aasm do
    state :shopping, initial: true
    state :coverage_selected, :after_enter => [:update_renewal_coverage, :handle_coverage_selection]
    state :transmitted_to_carrier
    state :coverage_enrolled, :after_enter => :update_renewal_coverage

    state :coverage_termination_pending
    state :coverage_canceled      # coverage never took effect
    state :coverage_terminated    # coverage ended
    state :coverage_reinstated    # coverage reinstated

    state :coverage_expired
    state :inactive, :after_enter => :update_renewal_coverage   # indicates SHOP 'waived' coverage. :after_enter inform census_employee

    # Verified Lawful Presence (VLP) flags
    state :unverified

    state :void       # nullify enrollment

    state :auto_renewing                    # customer passsively renewed into new product at start of Open Enrollment
    state :renewing_waived                  # customer voluntarily declined benefit enrollment
    state :renewing_coverage_selected       # customer actively selected product during Open Enrollment
    state :renewing_transmitted_to_carrier
    state :renewing_coverage_enrolled       # effectuated

    state :auto_renewing_contingent         # VLP-pending customer passsively renewed into new product at start of Open Enrollment
    state :renewing_contingent_selected     # VLP-pending customer actively selected product during Open Enrollment
    state :renewing_contingent_transmitted_to_carrier
    state :renewing_contingent_enrolled
    state :actively_renewing                #It is a temporary lasting initial state for auto generated renewal enrollment

    # after_all_transitions :perform_employer_plan_year_count

    event :renew_enrollment, :after => :record_transition do
      transitions from: :shopping, to: :auto_renewing, after: :propagate_renewal
    end

    event :renew_waived, :after => :record_transition do
      transitions from: :shopping, to: :renewing_waived
    end

    event :select_coverage, :after => [:record_transition, :propagate_selection] do
      transitions from: :shopping,
                  to: :coverage_selected, :guard => :can_select_coverage?
      transitions from: [:auto_renewing, :actively_renewing],
                  to: :renewing_coverage_selected, :guard => :can_select_coverage?
      transitions from: :auto_renewing_contingent,
                  to: :renewing_contingent_selected, :guard => :can_select_coverage?
    end

    event :transmit_coverage, :after => :record_transition do
      transitions from: :coverage_selected, to: :transmitted_to_carrier
      transitions from: :auto_renewing, to: :renewing_transmitted_to_carrier
      transitions from: :renewing_coverage_selected, to: :renewing_transmitted_to_carrier
      transitions from: :renewing_contingent_selected, to: :renewing_contingent_transmitted_to_carrier
    end

    event :effectuate_coverage, :after => :record_transition do
      transitions from: :transmitted_to_carrier, to: :coverage_enrolled
      transitions from: :renewing_transmitted_to_carrier, to: :renewing_coverage_enrolled
      transitions from: :renewing_contingent_transmitted_to_carrier, to: :renewing_contingent_enrolled
    end

    event :waive_coverage, :after => :record_transition do
      transitions from: [:shopping, :coverage_selected, :auto_renewing, :renewing_coverage_selected],
                  to: :inactive, after: :propogate_waiver
    end

    event :begin_coverage, :after => :record_transition do
      transitions from: [:auto_renewing, :renewing_coverage_selected, :renewing_transmitted_to_carrier,
                         :renewing_coverage_enrolled, :coverage_selected, :transmitted_to_carrier,
                         :auto_renewing_contingent, :renewing_contingent_selected, :renewing_contingent_transmitted_to_carrier,
                         :coverage_renewed, :unverified],
                  to: :coverage_enrolled, :guard => :is_shop?

      transitions from: [:auto_renewing, :renewing_coverage_selected, :coverage_reinstated], to: :coverage_selected
      transitions from: :renewing_waived, to: :inactive
    end

    event :expire_coverage, :after => :record_transition do
      transitions from: [:shopping, :coverage_selected, :transmitted_to_carrier, :coverage_enrolled, :unverified],
                  to: :coverage_expired, :guard  => :can_be_expired?
    end

    event :schedule_coverage_termination, :after => :record_transition do
      transitions from: [:coverage_termination_pending, :coverage_selected, :auto_renewing,
                         :coverage_enrolled],
                  to: :coverage_termination_pending, after: :set_coverage_termination_date

      transitions from: [:renewing_waived, :inactive], to: :inactive
    end

    event :cancel_coverage, :after => :record_transition do
      transitions from: [:coverage_termination_pending, :auto_renewing, :renewing_coverage_selected,
                         :renewing_transmitted_to_carrier, :renewing_coverage_enrolled, :coverage_selected,
                         :transmitted_to_carrier, :coverage_renewed, :unverified,
                         :coverage_enrolled, :renewing_waived, :inactive, :coverage_reinstated],
                  to: :coverage_canceled, after: :propogate_cancel
      transitions from: :coverage_expired, to: :coverage_canceled, :guard => :is_ivl_by_kind?, after: :propogate_cancel
    end

    event :cancel_for_non_payment, :after => :record_transition do
      transitions from: [:coverage_termination_pending, :auto_renewing, :renewing_coverage_selected,
                         :renewing_transmitted_to_carrier, :renewing_coverage_enrolled, :coverage_selected,
                         :transmitted_to_carrier, :coverage_renewed, :unverified,
                         :coverage_enrolled, :renewing_waived, :inactive],
                  to: :coverage_canceled, after: :propogate_cancel
      transitions from: :coverage_expired, to: :coverage_canceled, :guard => :is_ivl_by_kind?, after: :propogate_cancel
    end

    event :terminate_coverage, :after => :record_transition do
      transitions from: [:coverage_termination_pending, :coverage_selected, :coverage_enrolled, :auto_renewing,
                         :renewing_coverage_selected,:auto_renewing_contingent, :renewing_contingent_selected,
                         :renewing_contingent_transmitted_to_carrier, :renewing_contingent_enrolled,
                         :unverified, :coverage_expired, :coverage_terminated],
                  to: :coverage_terminated, after: :propogate_terminate
    end

    event :terminate_for_non_payment, :after => :record_transition do
      transitions from: [:coverage_termination_pending, :coverage_selected, :coverage_enrolled, :auto_renewing,
                         :renewing_coverage_selected,:auto_renewing_contingent, :renewing_contingent_selected,
                         :renewing_contingent_transmitted_to_carrier, :renewing_contingent_enrolled,
                         :unverified],
                  to: :coverage_terminated, after: :propogate_terminate
    end

    event :invalidate_enrollment, :after => :record_transition do
      transitions from: [:coverage_termination_pending, :coverage_canceled, :coverage_terminated],
                  to: :void,
                  guard: :termination_attributes_cleared?

      transitions from: [:shopping, :coverage_selected, :coverage_enrolled, :transmitted_to_carrier,
                         :coverage_expired, :inactive, :unverified, :void,
                         :auto_renewing, :renewing_waived, :renewing_coverage_selected,
                         :renewing_transmitted_to_carrier, :renewing_coverage_enrolled,
                         :auto_renewing_contingent, :renewing_contingent_selected,
                         :renewing_contingent_transmitted_to_carrier, :renewing_contingent_enrolled],
                  to:  :void
    end

    event :move_to_enrolled, :after => :record_transition do
      transitions from: :unverified, to: :coverage_selected
    end

    event :move_to_pending, :after => :record_transition do
      transitions from: :shopping, to: :unverified
      transitions from: :coverage_selected, to: :unverified
      transitions from: :coverage_enrolled, to: :unverified
      transitions from: :auto_renewing, to: :unverified
    end

    event :force_select_coverage, :after => :record_transition do
      transitions from: :shopping, to: :coverage_selected, after: :propagate_selection
    end

    event :reinstate_coverage, :after => :record_transition do
      transitions from: :shopping, to: :coverage_reinstated
    end
  end

  def termination_attributes_cleared?
    update_attributes({terminated_on: nil, terminate_reason: nil})
    (terminated_on == nil) && (terminate_reason == nil)
  end

  def can_be_expired?
    benefit_group.blank? || (benefit_group.present? && benefit_group.end_on <= TimeKeeper.date_of_record)
  end

  def can_select_coverage?(qle: false)
    return true if is_cobra_status?
    if is_shop?
      if employee_role.can_enroll_as_new_hire?
        coverage_effective_date = employee_role.coverage_effective_on(current_benefit_group: sponsored_benefit_package, qle: qle)
      elsif special_enrollment_period.present? && special_enrollment_period.contains?(TimeKeeper.date_of_record)
        coverage_effective_date = special_enrollment_period.effective_on
      elsif sponsored_benefit_package.benefit_application.open_enrollment_contains?(TimeKeeper.date_of_record)
        open_enrollment_effective_date = sponsored_benefit_package.benefit_application.start_on
        return false if open_enrollment_effective_date < employee_role.coverage_effective_on(current_benefit_group: sponsored_benefit_package)
        coverage_effective_date = open_enrollment_effective_date
      end

      # TODO: Have Trey confirm this isn't necessary anymore
      # benefit_group_assignment_valid?(coverage_effective_date)
    else
      true
    end
  end

  def assign_cost_decorator(decorator)
    @cost_decorator = decorator
  end

  def decorated_hbx_enrollment
    if is_shop?
      @group_enrollment ||= HbxEnrollmentSponsoredCostCalculator.new(self).groups_for_products([product]).first.group_enrollment
    else
      ivl_decorated_hbx_enrollment
    end
  end

  def ivl_decorated_hbx_enrollment(enrollment_product = nil)
    return @cost_decorator if @cost_decorator
    enrollment_product ||= product
    if enrollment_product.present? && (resident_role.present? || consumer_role.present?)
      @cost_decorator = UnassistedPlanCostDecorator.new(enrollment_product, self)
    else
      log("#3835 hbx_enrollment without benefit_group and consumer_role. hbx_enrollment_id: #{id}, plan: #{product}", {:severity => 'error'})
      @cost_decorator = OpenStruct.new(:total_premium => 0.00, :total_employer_contribution => 0.00, :total_employee_cost => 0.00, :total_ehb_premium => 0.00)
    end
  end

  def eligibility_event_kind
    if (enrollment_kind == "special_enrollment")
      return "unknown_sep" if special_enrollment_period.blank?
      qle_reason = special_enrollment_period.qualifying_life_event_kind.reason
      return QualifyingLifeEventKind::REASON_KINDS.include?(qle_reason) ? qle_reason : "unknown_sep"
    end

    return "open_enrollment" if !is_shop?
    if is_shop? && is_cobra_status?
      if cobra_eligibility_date == effective_on
        return "employer_sponsored_cobra"
      end
    end
    if !benefit_sponsorship_id.blank?
      # TODO: THIS IS A HACK
      # HACK: I JUST SAID SO, AND IT TOTALLY IS
      # FIXME: THIS EXISTS ONLY FOR INITIAL MPY - REMOVE THIS AFTER THEY ARE SENT
      return "open_enrollment" if benefit_sponsorship.is_mid_plan_year_conversion?
    end
    new_hire_enrollment_for_shop? ? "new_hire" : check_for_renewal_event_kind
  end

  def cobra_eligibility_date
    employee_role.census_employee.cobra_begin_date
  end

  def check_for_renewal_event_kind
    if RENEWAL_STATUSES.include?(self.aasm_state) || was_in_renewal_status?
      return "passive_renewal"
    end
    "open_enrollment"
  end

  def was_in_renewal_status?
    workflow_state_transitions.any? do |wst|
      RENEWAL_STATUSES.include?(wst.from_state.to_s)
    end
  end

  def eligibility_event_date
    if is_special_enrollment?
      return nil if special_enrollment_period.nil?
      return special_enrollment_period.qle_on
    end
    return nil if !is_shop?
    return self.employee_role.census_employee.cobra_begin_date if is_shop? && is_cobra_status?
    new_hire_enrollment_for_shop? ? benefit_group_assignment.census_employee.hired_on : nil
  end

  def eligibility_event_has_date?
    if is_special_enrollment?
      return false if special_enrollment_period.nil?
      return true
    end
    return false unless is_shop?
    return true if is_shop? && is_cobra_status?
    new_hire_enrollment_for_shop?
  end

  def new_hire_enrollment_for_shop?
    return false if is_special_enrollment?
    return false unless is_shop?
    shopping_plan_year = sponsored_benefit_package.benefit_application
    purchased_at = [submitted_at, created_at].compact.max
    return true unless (shopping_plan_year.open_enrollment_period.min..shopping_plan_year.open_enrollment_period.max).include?(TimeKeeper.date_according_to_exchange_at(purchased_at))
    !(shopping_plan_year.effective_period.min== effective_on)
  end

  def update_coverage_kind_by_plan
    update(coverage_kind: product.kind) if product.present? && coverage_kind != product.kind
  end

  def set_submitted_at
    if submitted_at.blank?
      write_attribute(:submitted_at, Time.now)
    end
  end

  def is_health_enrollment?
    coverage_kind == "health"
  end

  def is_dental_enrollment?
    coverage_kind == "dental"
  end

  def plan_year_check(employee_role)
    covered_plan_year(employee_role).present? && !covered_plan_year(employee_role).send(:can_be_migrated?)
  end

  def covered_plan_year(employee_role)
    employee_role.employer_profile.plan_years.detect { |py| (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(family.current_sep.try(:effective_on))} if employee_role.present?
  end

  def event_submission_date
    submitted_at.blank? ? Time.now : submitted_at
  end

  def is_reinstated_enrollment?
    self.workflow_state_transitions.any?{|w| w.from_state == "coverage_reinstated"}
  end

  def dental?
    coverage_kind == "dental"
  end

  # TODO: Implement behaviour by 16219.
  def composite_rating_tier
    @composite_rating_tier ||= cached_composite_rating_tier
  end

  def cached_composite_rating_tier
    return nil unless is_shop?
    return CompositeRatingTier::EMPLOYEE_ONLY unless hbx_enrollment_members.many?
    relationships = hbx_enrollment_members.reject(&:is_subscriber?).map do |mem|
      PlanCostDecorator.benefit_relationship(mem.primary_relationship)
    end
    if (relationships.include?("spouse") || relationships.include?("domestic_partner"))
      relationships.many? ? CompositeRatingTier::FAMILY : CompositeRatingTier::EMPLOYEE_AND_SPOUSE
    else
      CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
    end
  end

  def composite_rated?
    return false if dental?
    return false if sponsored_benefit_package_id.blank?
    return false if sponsored_benefit.blank?
    sponsored_benefit.single_plan_type? && sponsored_benefit.pricing_determinations.any?
  end

  def any_dependent_members_age_above_26?
    hbx_enrollment_members.where(is_subscriber: false).map(&:family_member).map(&:person).each do |person|
      return true if person.age_on(TimeKeeper.date_of_record) >= 26
    end
    return false
  end

  def is_active_renewal_purchase?
    enrollment = self.household.hbx_enrollments.ne(id: id).by_coverage_kind(coverage_kind).by_year(effective_on.year).by_kind(kind).cancel_eligible.last rescue nil
    !is_shop? && is_open_enrollment? && enrollment.present? && ['auto_renewing', 'renewing_coverage_selected'].include?(enrollment.aasm_state)
  end

  def is_ivl_by_kind?
    (Kinds - ["employer_sponsored", "employer_sponsored_cobra"]).include?(kind)
  end

  def is_enrolled_by_aasm_state?
    ENROLLED_STATUSES.include?(aasm_state)
  end

  def is_ivl_and_outstanding?
    is_ivl_by_kind? && is_any_enrollment_member_outstanding? && ENROLLED_AND_RENEWAL_STATUSES.include?(self.aasm_state)
  end

  def is_effective_in_current_year?
    (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year).include?(effective_on)
  end

  def is_ivl_actively_outstanding?
    is_ivl_by_kind? && is_enrolled_by_aasm_state? && is_effective_in_current_year? && is_any_enrollment_member_outstanding?
  end

  def is_any_member_outstanding?
    active_consumer_role_people =  hbx_enrollment_members.flat_map(&:person).select{|per| per if per.is_consumer_role_active?}
    active_consumer_role_people.present? ? active_consumer_role_people.map(&:consumer_role).any?(&:verification_outstanding?) : false
  end

  EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled) do
    def is_disabled?
      is_disabled
    end

    def is_primary_member?
      is_primary_member
    end
  end

  def as_shop_member_group
    roster_members = []
    group_enrollment_members = []
    previous_enrollment = self.parent_enrollment
    previous_product = nil
    if previous_enrollment
      previous_product = previous_enrollment.product
    end

    hbx_enrollment_members.each do |hem|
      person = hem.person
      roster_member = EnrollmentMemberAdapter.new(
        hem.id,
        person.dob,
        hem.primary_relationship,
        hem.is_subscriber?,
        person.is_disabled
      )
      roster_members << roster_member
      group_enrollment_member = BenefitSponsors::Enrollments::MemberEnrollment.new({
        member_id: hem.id,
        coverage_eligibility_on: hem.coverage_start_on
      })
      group_enrollment_members << group_enrollment_member
    end
    group_enrollment = BenefitSponsors::Enrollments::GroupEnrollment.new(
      previous_product: previous_product,
      coverage_start_on: effective_on,
      member_enrollments: group_enrollment_members,
      rate_schedule_date: sponsored_benefit.rate_schedule_date,
      rating_area: rating_area.exchange_provided_code,
      sponsor_contribution_prohibited: is_cobra_status?
    )
    BenefitSponsors::Members::MemberGroup.new(
      roster_members,
      group_id: self.id,
      group_enrollment: group_enrollment
    )
  end

  def notify_enrollment_cancel_or_termination_event(transmit_flag)
    return unless coverage_terminated? || coverage_canceled? || coverage_termination_pending?

    config = Rails.application.config.acapi
    notify(
      "acapi.info.events.hbx_enrollment.terminated",
      {
        :reply_to => "#{config.hbx_id}.#{config.environment_name}.q.glue.enrollment_event_batch_handler",
        "hbx_enrollment_id" => hbx_id,
        "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        "is_trading_partner_publishable" => transmit_flag
      }
    )
  end

  def cancel_ivl_enrollment
    return if is_shop?

    previous_state = self.aasm_state
    self.update_attributes(aasm_state: 'coverage_canceled')
    workflow_state_transitions << WorkflowStateTransition.new(from_state: previous_state,
                                                              to_state: 'coverage_canceled')
  end

  def cancel_terminated_enrollment(termination_date, edi_required)
    if effective_on == termination_date
      prevs_state = self.aasm_state
      self.update_attributes(aasm_state: "coverage_canceled", terminated_on: nil, termination_submitted_on: nil, terminate_reason: nil)
      workflow_state_transitions << WorkflowStateTransition.new(
          from_state: prevs_state,
          to_state: "coverage_canceled"
      )
      self.notify_enrollment_cancel_or_termination_event(edi_required)
      return true
    end
  end

  def reterm_enrollment_with_earlier_date(termination_date, edi_required)

    return false unless self.coverage_terminated? || self.coverage_termination_pending?
    return false if termination_date > self.terminated_on
    return true if cancel_terminated_enrollment(termination_date, edi_required)

    if self.is_shop? && (termination_date > ::TimeKeeper.date_of_record && self.may_schedule_coverage_termination?)
      self.schedule_coverage_termination!(termination_date)
      self.notify_enrollment_cancel_or_termination_event(edi_required)
      return true
    elsif self.may_terminate_coverage?
      self.terminated_on = termination_date
      self.terminate_coverage!(termination_date)
      self.notify_enrollment_cancel_or_termination_event(edi_required)
      return true
    else
      false
    end
  end

  def is_any_member_outstanding?
    active_consumer_role_people =  hbx_enrollment_members.flat_map(&:person).select{|per| per if per.is_consumer_role_active?}
    active_consumer_role_people.present? ? active_consumer_role_people.map(&:consumer_role).any?(&:verification_outstanding?) : false
  end

  def is_admin_active_enrolled_and_renewing?
    is_active && (ENROLLED_STATUSES + RENEWAL_STATUSES).map(&:to_s).include?(aasm_state.to_s)
  end

  def is_admin_cancel_eligible?
    ["coverage_selected", "renewing_coverage_selected", "coverage_enrolled", "auto_renewing", "unverified"].include?(aasm_state.to_s)
  end

  def is_admin_reinstate_or_end_date_update_eligible?
    CAN_REINSTATE_AND_UPDATE_END_DATE.include?(aasm_state.to_s)
  end

  def is_admin_terminate_eligible?
    CAN_TERMINATE_ENROLLMENTS.map(&:to_s).include?(aasm_state.to_s)
  end

  def previous_enrollments(year)
    household.hbx_enrollments.ne(id: id).by_coverage_kind(self.coverage_kind).by_year(year).show_enrollments_sans_canceled.by_kind(self.kind)
  end

  def generate_signature(previous_enrollment)
    previous_enrollment.update_attributes(enrollment_signature: previous_enrollment.generate_hbx_signature) unless previous_enrollment.enrollment_signature.present?
  end

  def same_signatures(previous_enrollment)
    previous_enrollment.enrollment_signature == self.enrollment_signature
  end

  private

  def set_is_any_enrollment_member_outstanding
    if kind == "individual"
      active_consumer_role_people = hbx_enrollment_members.flat_map(&:person).select{|per| per if per.is_consumer_role_active?}
      true_or_false = active_consumer_role_people.present? ? active_consumer_role_people.map(&:consumer_role).any?(&:verification_outstanding?) : false
      self.assign_attributes({:is_any_enrollment_member_outstanding => true_or_false})
    end
  end

  # NOTE - Mongoid::Timestamps does not generate created_at time stamps.
  def check_created_at
    self.update_attribute(:created_at, TimeKeeper.datetime_of_record) unless self.created_at.present?
  end

  def benefit_group_assignment_valid?(coverage_effective_date)
    plan_year = employee_role.employer_profile.find_plan_year_by_effective_date(coverage_effective_date)
    if plan_year.present? && benefit_group_assignment.plan_year == plan_year
      true
    else
      self.errors.add(:base, "You can not keep an existing plan which belongs to previous plan year")
      false
    end
  end
end
