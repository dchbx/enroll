# BenefitSponsorship
# Manage benfit enrollment activity for a sponsoring Organization's Profile (e.g. EmployerProfile,
# HbxProfile, etc.) Behavior is goverened by settings obtained from the BenefitMarkets::BenefitCatelog.
# Typically assumes a once annual enrollment period and effective date.  For scenarios where there's a
# once-yearly open enrollment, new sponsors may join mid-year for initial enrollment, subsequently
# renewing on-schedule in following cycles. Scenarios where enollments are conducted on a rolling monthly
# basis are also supported.

# Organzations may embed many BenefitSponsorships.  Significant changes result in new BenefitSponsorship,
# such as the following supported scenarios:
# - Benefit Sponsor (employer) voluntarily terminates and later returns after some elapsed period
# - Benefit Sponsor is involuntarily terminated (such as for non-payment) and later becomes eligible
# - Existing Benefit Sponsor changes effective date

# Referencing a new BenefitSponsorship helps ensure integrity on subclassed and associated data models and
# enables history tracking as part of the models structure
module BenefitSponsors
  class BenefitSponsorships::BenefitSponsorship
    include Mongoid::Document
    include Mongoid::Timestamps
    include BenefitSponsors::Concerns::RecordTransition
    include BenefitSponsors::Concerns::EmployerDatatableConcern
    include BenefitSponsors::Concerns::Observable
    include BenefitSponsors::ModelEvents::BenefitSponsorship

    # include Config::AcaModelConcern
    # include Concerns::Observable
    include AASM

    ACTIVE_STATES   = [:applicant, :initial_application_under_review, :initial_application_denied, :initial_application_approved,
                        :initial_enrollment_open, :initial_enrollment_closed, :initial_enrollment_ineligible, :binder_reversed, :active].freeze
    INACTIVE_STATES = [:suspended, :ineligible, :teminated].freeze
    ENROLLED_STATES = [:enrolled]

    INVOICE_VIEW_INITIAL  ||= %w(published enrolling enrolled active suspended)
    INVOICE_VIEW_RENEWING ||= %w(renewing_published renewing_enrolling renewing_enrolled renewing_draft)


    # Origination of this BenefitSponsorship instance in association
    # with BenefitMarkets::APPLICATION_INTERVAL_KINDS
    #   :self_serve               =>  sponsor independently joined HBX with initial effective date
    #                                 coinciding with standard benefit application interval
    #   :conversion               =>  sponsor transferred to HBX with initial effective date
    #                                 immediately following benefit expiration in prior system
    #   :mid_plan_year_conversion =>  sponsor transferred to HBX with effective date during active plan
    #                                 year, before benefit expiration in prior system, and benefits are
    #                                 carried over to HBX
    #   :reapplied                =>  sponsor, previously active on HBX, voluntarily terminated early
    #                                 and sponsorship continued without interuption, or sponsor returned
    #                                 following time period gap in benefit coverage
    #   :restored                 =>  sponsor, previously active on HBX, was involuntarily terminated
    #                                 and sponsorship resumed according to HBX policy
    SOURCE_KINDS              = [:self_serve, :conversion, :mid_plan_year_conversion, :reapplied, :restored].freeze

    TERMINATION_KINDS         = [:voluntary, :involuntary].freeze
    TERMINATION_REASON_KINDS  = [:nonpayment, :ineligible, :fraud].freeze

    field :hbx_id,              type: String
    field :profile_id,          type: BSON::ObjectId

    # Effective begin/end are the date period during which this benefit sponsorship is active
    # Date when initial application coverage starts for this sponsor
    field :effective_begin_on,  type: Date

    # When present, date when all benefit applications are terminated and sponsorship ceases
    field :effective_end_on,    type: Date
    field :termination_kind,    type: Symbol
    field :termination_reason,  type: Symbol

    field :predecessor_id,  type: BSON::ObjectId

    # Immutable value indicating origination of this BenefitSponsorship
    field :source_kind,         type: Symbol, default: :self_serve
    field :registered_on,       type: Date,   default: ->{ TimeKeeper.date_of_record }

    # This sponsorship's workflow status
    field :aasm_state,          type: Symbol, default: :applicant do
      error_on_all_events { |e| raise WMS::MovementError.new(e.message, original_exception: e, model: self) }
    end

    delegate :sic_code,     :sic_code=,     to: :profile, allow_nil: true
    delegate :primary_office_location,      to: :profile, allow_nil: true
    delegate :enforce_employer_attestation, to: :benefit_market

    belongs_to  :organization,
      inverse_of: :benefit_sponsorships,
      counter_cache: true,
      class_name: "BenefitSponsors::Organizations::Organization"

    embeds_many :benefit_applications,
      class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication"

    has_many    :census_employees,
      class_name: "::CensusEmployee"

    belongs_to  :benefit_market,
      counter_cache: true,
      class_name: "::BenefitMarkets::BenefitMarket"

    belongs_to  :rating_area,
      counter_cache: true,
      class_name: "::BenefitMarkets::Locations::RatingArea"

    has_and_belongs_to_many :service_areas,
      :inverse_of => nil,
      class_name: "::BenefitMarkets::Locations::ServiceArea"

    embeds_many :broker_agency_accounts, class_name: "BenefitSponsors::Accounts::BrokerAgencyAccount",
      validate: true

    embeds_many :general_agency_accounts, class_name: "BenefitSponsors::Accounts::GeneralAgencyAccount",
      validate: true

    embeds_one  :employer_attestation, class_name: "BenefitSponsors::Documents::EmployerAttestation"

    has_many    :documents,
      inverse_of: :benefit_sponsorship_docs,
      class_name: "BenefitSponsors::Documents::Document"

    validates_presence_of :organization, :profile_id, :benefit_market, :source_kind

    validates :source_kind,
      inclusion: { in: SOURCE_KINDS, message: "%{value} is not a valid source kind" },
      allow_blank: false

    # Workflow attributes
    scope :active,                      ->{ any_in(aasm_state: ACTIVE_STATES) }
    scope :inactive,                    ->{ any_in(aasm_state: INACTIVE_STATES) }

    scope :by_broker_role,              ->( broker_role_id ){ where(:'broker_agency_accounts' => {:$elemMatch => { is_active: true, writing_agent_id: broker_role_id} }) }
    scope :by_broker_agency_profile,    ->( broker_agency_profile_id ) { where(:'broker_agency_accounts' => {:$elemMatch => { is_active: true, benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id} }) }

    scope :may_begin_open_enrollment?,  -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"open_enrollment_period.min".lte => compare_date, :aasm_state => :approved }}
      )
    }

    scope :may_end_open_enrollment?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"open_enrollment_period.max".lt => compare_date, :aasm_state => :enrollment_open }}
      )
    }

    scope :may_begin_benefit_coverage?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"effective_period.min".lte => compare_date, :aasm_state => :enrollment_eligible }}
      )
    }

    scope :may_end_benefit_coverage?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"effective_period.max".lt => compare_date, :aasm_state => :active }}
      )
    }

    scope :may_renew_application?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"effective_period.max" => compare_date, :aasm_state => :active }}
      )
    }

    scope :eligible_renewal_applications_on, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {
          :"effective_period.min" => compare_date,
          :predecessor_id => {"$ne" => nil},
          :aasm_state => {"$in" => [:enrollment_eligible, :active]}
        }
      })
    }

    # Fix Me: verify the state check...probably need to use termination_pending
    scope :may_terminate_benefit_coverage?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"terminated_on" => compare_date, :aasm_state.in => [:active, :suspended] }}
      )
    }

    scope :may_transmit_initial_enrollment?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"effective_period.min" => compare_date, :aasm_state => :enrollment_eligible}},
        :aasm_state => :initial_enrollment_eligible
      )
    }

    scope :may_transmit_renewal_enrollment?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:predecessor_id => { :$exists => true }, :"effective_period.min" => compare_date, :aasm_state => :enrollment_eligible }},
        :aasm_state => :active
      )
    }

    scope :may_auto_submit_application?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:predecessor_id => { :$exists => true }, :"effective_period.min" => compare_date, :aasm_state => :draft }}
      )
    }

    scope :mark_initial_ineligible?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:predecessor_id => { :$exists => false }, :"effective_period.min" => compare_date, :aasm_state => :enrollment_closed }}
      )
    }

    scope :may_cancel_ineligible_application?, -> (compare_date = TimeKeeper.date_of_record) {
      where(:benefit_applications => {
        :$elemMatch => {:"effective_period.min" => compare_date, :aasm_state => :enrollment_ineligible }}
      )
    }

    scope :benefit_application_find,     ->(ids) {
      where(:"benefit_applications._id".in => [ids].flatten.collect{|id| BSON::ObjectId.from_string(id)})
    }

    scope :benefit_package_find,         ->(id) {
      where(:"benefit_applications.benefit_packages._id" => BSON::ObjectId.from_string(id))
    }

    scope :by_profile,                   ->(profile) {
      where(:profile_id => profile._id)
    }

    index({ hbx_id: 1 })
    index({ aasm_state: 1 })
    index({ profile_id: 1 })

    index({"benefit_application._id" => 1})
    index({"benefit_application.predecessor_id" => 1})
    index({ "benefit_application.aasm_state" => 1, "effective_period.min" => 1, "effective_period.max" => 1},
            { name: "effective_period" })

    index({ "benefit_application.aasm_state" => 1, "open_enrollment_period.min" => 1, "open_enrollment_period.max" => 1},
            { name: "open_enrollment_period" })

    add_observer ::BenefitSponsors::Observers::BenefitSponsorshipObserver.new, [:notifications_send]
    after_save :notify_on_save
    before_create :generate_hbx_id
    before_validation :pull_profile_attributes, :pull_organization_attributes, :validate_profile_organization

    def application_may_renew_effective_on(new_date)
      benefit_applications.effective_date_end_on(new_date).coverage_effective.first
    end

    def application_may_begin_open_enrollment_on(new_date)
      benefit_applications.open_enrollment_begin_on(new_date).approved.first
    end

    def application_may_end_open_enrollment_on(new_date)
      benefit_applications.open_enrollment_end_on(new_date).enrolling_state.first
    end

    def application_may_begin_benefit_on(new_date)
      benefit_applications.effective_date_begin_on(new_date).enrollment_eligible.first
    end

    def application_may_end_benefit_on(new_date)
      benefit_applications.effective_date_end_on(new_date).coverage_effective.first
    end

    def application_may_terminate_on(terminated_on)
      benefit_applications.benefit_terminate_on(terminated_on).first
    end

    def application_may_auto_submit(effective_date)
      benefit_applications.effective_date_begin_on(effective_date).renewing.draft_state.first
    end

    def primary_office_address
      primary_office_location.address if has_primary_office_address?
    end

    def service_areas_on(a_date = ::TimeKeeper.date_of_record)
      if has_primary_office_address?
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(primary_office_location.address, during: a_date).to_a
      else
        []
      end
    end

    def rating_area_on(a_date = ::TimeKeeper.date_of_record)
      if has_primary_office_address?
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(primary_office_location.address, during: a_date)
      else
        nil
      end
    end

    def primary_office_rating_area
      rating_area_on(::TimeKeeper.date_of_record)
    end

    def primary_office_service_areas
      service_areas_on(::TimeKeeper.date_of_record)
    end

    def has_primary_office_address?
      primary_office_location.present? && primary_office_location.address.present?
    end

    # Inverse of Profile#benefit_sponsorship
    def profile
      return @profile if defined?(@profile)
      @profile = BenefitSponsors::Organizations::Organization.by_employer_profile(self.profile_id).first.employer_profile unless profile_id.blank?
    end

    def profile=(new_profile)
      if new_profile.nil?
        write_attribute(:profile_id, nil)
        @profile = nil
        self.organization = nil
      else
        write_attribute(:profile_id, new_profile._id)
        @profile = new_profile
        self.organization = new_profile.organization
        pull_profile_attributes
        pull_organization_attributes
      end
      @profile
    end

    # Watch for changes in Profile
    def profile_event_subscriber(event)
      if event == :primary_office_location_change && ![:terminated, :ineligible].include?(aasm_state)
        pull_profile_attributes
        self.save!
      end
    end

    def reset_organization=(new_organization)
      if new_organization.nil?
        self.organization = nil
        self.benefit_market = nil
      else
        self.organization = new_organization
        pull_organization_attributes
      end
    end

    def predecessor=(benefit_sponsorship)
      raise ArgumentError.new("expected BenefitSponsorship") unless benefit_sponsorship.is_a? BenefitSponsors::BenefitSponsorships::BenefitSponsorship
      self.predecessor_id = benefit_sponsorship._id
      @predecessor = benefit_sponsorship
    end

    def predecessor
      return nil if predecessor_id.blank?
      return @predecessor if defined? @predecessor
      @predecessor = profile.find_benefit_sponsorships(predecessor_id)
    end

    def successors
      return [] if profile.blank?
      return @successors if defined? @successors
      @successors = profile.benefit_sponsorship_successors_for(self)
    end

    def roster_size
      return @roster_size if defined? @roster_size
      @roster_size = census_employees.active.size
    end

    def is_eligible?
      ["ineligible", "terminated"].exclude?(aasm_state)
    end

    def benefit_sponsor_catalog_for(recorded_service_areas, effective_date)
      benefit_market_catalog = benefit_market.benefit_market_catalog_effective_on(effective_date)
      benefit_market_catalog.benefit_sponsor_catalog_for(service_areas: recorded_service_areas, effective_date: effective_date)
    end

    def published_benefit_application
      benefit_applications.submitted.last
    end

    def submitted_benefit_application
      # renewing_published_plan_year || active_plan_year ||
      published_benefit_application
    end

    def benefit_applications_by(ids)
      benefit_applications.find(ids)
    end

    def benefit_application_successors_for(benefit_application)
      benefit_applications.select { |sponsorship_benefit_application| sponsorship_benefit_application.predecessor_id == benefit_application._id}
    end

    def benefit_package_by(id)
      benefit_application = benefit_applications.where(:"benefit_packages._id" => BSON::ObjectId.from_string(id)).first
      if benefit_application
        benefit_application.benefit_packages.unscoped.find(id)
      end
    end

    def is_attestation_eligible?
      return true unless enforce_employer_attestation
      employer_attestation.present? && employer_attestation.is_eligible?
    end

    # If there is a gap, it will fall under a new benefit sponsorship
    # Renewal_benefit_application's predecessor is always current benefit application
    # most_recent_benefit_application will always be their current benefit_application if no renewal
    def current_benefit_application
      renewal_benefit_application.present? ? renewal_benefit_application.predecessor : most_recent_benefit_application
    end

    def renewal_benefit_application
      benefit_applications.order_by(:"created_at".desc).detect {|application| application.is_renewing? }
    end

    def active_benefit_application
      benefit_applications.order_by(:"created_at".desc).detect {|application| application.active?}
    end

    def most_recent_benefit_application
      benefit_applications.order_by(:"created_at".desc).first
    end

    def renewing_submitted_benefit_application # TODO -recheck
      benefit_applications.order_by(:"created_at".desc).detect {|application| application.is_renewal_enrolling? }
    end

    alias_method :renewing_published_benefit_application, :renewing_submitted_benefit_application
    alias_method :latest_benefit_application, :most_recent_benefit_application

    # TODO: pass in termination reason and kind
    def terminate_enrollment(benefit_end_date)
      if self.may_terminate?
        self.terminate!
        self.update_attributes(effective_end_on: benefit_end_on, termination_kind: :voluntary, termination_reason: :nonpayment)
      end
    end


    #### TODO FIX Move these methods to domain logic layer
    def is_renewal_transmission_eligible?
      renewal_benefit_application.present? && renewal_benefit_application.enrollment_eligible?
    end

    def is_renewal_carrier_drop?
      if is_renewal_transmission_eligible?
        carriers_dropped_for(:health).any? || carriers_dropped_for(:dental).any?
      else
        true
      end
    end

    def carriers_dropped_for(product_kind)
      active_benefit_application.issuers_offered_for(product_kind) - renewal_benefit_application.issuers_offered_for(product_kind)
    end
    ####


    # Workflow for self service
    aasm do
      state :applicant, initial: true
      state :initial_application_under_review # Sponsor's first application is submitted invalid and under HBX review
      state :initial_application_denied       # Sponsor's first application is rejected
      state :initial_application_approved     # Sponsor's first application is submitted and approved
      state :initial_enrollment_open          # Sponsor members are under first open enrollment period
      state :initial_enrollment_closed        # Sponsor members' have successfully completed first open enrollment
      state :initial_enrollment_ineligible    # Sponsor members' first open enrollment has failed to meet eligibility policies
      state :initial_enrollment_eligible      # Sponsor has paid first premium in-full and authorized to offer benefits
      state :binder_reversed                  # Spnosor's initial payment is returned
      state :active                           # Sponsor's members are actively enrolled in coverage
      state :suspended                        # Premium payment is 61-90 days past due and Sponsor's benefit coverage has lapsed
      state :terminated                       # Sponsor's ability to offer benefits under this BenefitSponsorship is permanently terminated
      state :ineligible                       # Sponsor is permanently banned from sponsoring benefits due to regulation or policy
      
      after_all_transitions :publish_state_transition

      event :approve_initial_application do
        transitions from: [:applicant, :initial_application_under_review], to: :initial_application_approved
      end

      event :review_initial_application do
        transitions from: :applicant, to: :initial_application_under_review
      end

      event :deny_initial_application do
        transitions from: :initial_application_under_review, to: :initial_application_denied
      end

      event :open_initial_enrollment do
        transitions from: :initial_application_approved, to: :initial_enrollment_open
      end

      event :close_initial_enrollment do
        transitions from: :initial_enrollment_open, to: :initial_enrollment_closed
      end

      event :approve_initial_enrollment_eligibility do
        transitions from: :initial_enrollment_closed, to: :initial_enrollment_eligible
        transitions from: :initial_enrollment_ineligible,  to: :initial_enrollment_eligible
      end

      event :deny_initial_enrollment_eligibility do
        transitions from: :initial_enrollment_closed, to: :initial_enrollment_ineligible
        transitions from: :initial_enrollment_eligible,  to: :initial_enrollment_ineligible
      end

      event :credit_binder do
        transitions from: [:initial_enrollment_closed, :binder_reversed], to: :initial_enrollment_eligible
      end

      event :reverse_binder do
        transitions from: :initial_enrollment_eligible, to: :binder_reversed
      end

      event :begin_coverage do
        transitions from: :initial_enrollment_eligible, to: :active
      end

      event :revert_to_applicant do
        transitions from: [:applicant, :initial_application_approved,
                          :initial_application_under_review, :initial_application_denied,
                          :initial_enrollment_closed, :initial_enrollment_eligible, :binder_reversed,
                          :initial_enrollment_ineligible], to: :applicant
      end

      event :terminate do
        transitions from: [:active, :suspended], to: :terminated
      end

      event :suspend do
        transitions from: :active, to: :suspended
      end

      event :reverse_suspension do
        transitions from: :suspended, to: :active
      end

      event :reinstate do
        transitions from: :terminated, to: :active
      end

      event :reactivate do
        transitions from: :terminated, to: :initial_application_approved
      end

      event :ban do
        transitions to: :ineligible
      end

      event :cancel, :after_commit => :publish_cancel do
        transitions from: [:initial_application_approved, :initial_enrollment_closed, :binder_reversed, :initial_enrollment_ineligible, :active], to: :applicant
      end
    end

    # Notify BenefitApplication that
    def publish_state_transition
      return unless [:initial_enrollment_eligible,
        :binder_reversed,
        :initial_enrollment_ineligible,
        :applicant
      ].include?(aasm.to_state)
      
      begin
        benefit_applications.each do |benefit_application|
          benefit_application.benefit_sponsorship_event_subscriber(aasm)
        end
      rescue
      end
    end

    # BenefitApplication        BenefitSponsorship
    # approved               -> initial_application_approved
    # enrollment_open         -> initial_enrollment_open
    # enrollment_closed      -> initial_enrollment_closed
    # application_ineligible -> initial_enrollment_ineligible
    # application_eligible   -> initial_enrollment_eligible
    # active                 -> active
    def application_event_subscriber(aasm)
      case aasm.to_state
      when :imported
        revert_to_applicant! if may_revert_to_applicant?
      when :approved
        approve_initial_application! if may_approve_initial_application?
      when :pending
        review_initial_application! if may_review_initial_application?
      when :denied
        deny_initial_application! if may_deny_initial_application?
      when :enrollment_open
        open_initial_enrollment! if may_open_initial_enrollment?
      when :enrollment_closed
        close_initial_enrollment! if may_close_initial_enrollment?
      when :enrollment_ineligible
        deny_initial_enrollment_eligibility! if may_deny_initial_enrollment_eligibility?
      when :active
        begin_coverage! if may_begin_coverage?
      when :expired
        cancel! if may_cancel?
      when :canceled
        cancel! if (may_cancel? && aasm.current_event == :activate_enrollment!)
      when :draft
        revert_to_applicant! if may_revert_to_applicant?
      end

    end

    def is_conversion?
      source_kind == :conversion
    end

    def is_mid_plan_year_conversion?
      source_kind.to_s == "mid_plan_year_conversion"
    end

    def active_broker_agency_account
      broker_agency_accounts.detect { |baa| baa.is_active }
    end


    def self.find_by_feins(feins)
      organizations = BenefitSponsors::Organizations::Organization.where(fein: {:$in => feins})
      where(:organization_id => {:$in => organizations.pluck(:_id)})
    end

    private

    def validate_profile_organization
      if organization.present? && profile.present?
        if organization == profile.organization
          return true
        else
          return errors.add(:organization, "must be profile's organization")
        end
      end
    end

    def refresh_rating_area
      self.rating_area = primary_office_rating_area if has_primary_office_address?
    end

    def refresh_service_areas
      self.service_areas = primary_office_service_areas
    end

    def pull_organization_attributes
      self.benefit_market = organization.site.benefit_market_for(:aca_shop) unless organization.blank?
    end

    def pull_profile_attributes
    end

    def generate_hbx_id
      write_attribute(:hbx_id, BenefitSponsors::Organizations::HbxIdGenerator.generate_benefit_sponsorship_id) if hbx_id.blank?
    end

    def employer_profile_to_benefit_sponsor_states_map
      {
        :applicant            => :applicant,
        :registered           => :initial_application_approved,
        :eligible             => :initial_enrollment_closed,
        :binder_paid          => :initial_enrollment_eligible,
        :enrolled             => :active,
        :suspended            => :suspended,
        :ineligible           => :ineligible
      }
    end
  end
end
