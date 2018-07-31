module BenefitSponsors
  class BenefitApplications::BenefitApplication
    include Mongoid::Document
    include Mongoid::Timestamps
    include Acapi::Notifiers
    include BenefitSponsors::Concerns::RecordTransition
    include ::BenefitSponsors::Concerns::Observable
    include ::BenefitSponsors::ModelEvents::BenefitApplication

    include AASM

    embedded_in :benefit_sponsorship,
                class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
                inverse_of: :benefit_applications

    APPLICATION_EXCEPTION_STATES  = [:pending, :assigned, :processing, :reviewing, :information_needed, :appealing].freeze
    APPLICATION_DRAFT_STATES      = [:draft, :imported] + APPLICATION_EXCEPTION_STATES.freeze
    APPLICATION_APPROVED_STATES   = [:approved].freeze
    APPLICATION_DENIED_STATES     = [:denied].freeze
    ENROLLING_STATES              = [:enrollment_open, :enrollment_closed].freeze
    ENROLLMENT_ELIGIBLE_STATES    = [:enrollment_eligible].freeze
    ENROLLMENT_INELIGIBLE_STATES  = [:enrollment_ineligible].freeze
    COVERAGE_EFFECTIVE_STATES     = [:active, :termination_pending].freeze
    TERMINATED_STATES             = [:suspended, :terminated, :canceled, :expired].freeze
    CANCELED_STATES               = [:canceled].freeze
    EXPIRED_STATES                = [:expired].freeze
    IMPORTED_STATES               = [:imported].freeze
    APPROVED_STATES               = [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible, :active, :suspended].freeze
    SUBMITTED_STATES              = ENROLLMENT_ELIGIBLE_STATES + APPLICATION_APPROVED_STATES + ENROLLING_STATES + COVERAGE_EFFECTIVE_STATES

    # Deprecated - Use SUBMITTED_STATES
    PUBLISHED_STATES = SUBMITTED_STATES

    BENEFIT_PACKAGE_MEMBERS_TRANSITION_MAP =  {
                                                  active:     :effectuate,
                                                  expired:    :expire,
                                                  terminated: :terminate,
                                                  canceled:   :cancel
                                                }


    # The date range when this application is active
    field :effective_period,        type: Range

    # The date range when members may enroll in benefit products
    # Stored locally to enable sponsor-level exceptions
    field :open_enrollment_period,  type: Range

    # The date on which this application was canceled or terminated
    field :terminated_on,           type: Date

    # This application's workflow status
    field :aasm_state,              type: Symbol,   default: :draft do
      error_on_all_events { |e| raise WMS::MovementError.new(e.message, original_exception: e, model: self) }
    end

    # Calculated Fields for DataTable
    # field :enrolled_summary,        type: Integer,  default: 0
    # field :waived_summary,          type: Integer,  default: 0

    # Sponsor self-reported number of full-time employees
    field :fte_count,               type: Integer,  default: 0

    # Sponsor self-reported number of part-time employess
    field :pte_count,               type: Integer,  default: 0

    # Sponsor self-reported number of Medicare Second Payers
    field :msp_count,               type: Integer,  default: 0

    # Sponsor's Standard Industry Classification code for period covered by this
    # application
    field :recorded_sic_code,       type: String

    field :predecessor_id,          type: BSON::ObjectId

    field :recorded_rating_area_id,     type: BSON::ObjectId
    field :recorded_service_area_ids,   type: Array, default: []

    field :benefit_sponsor_catalog_id,  type: BSON::ObjectId

    delegate :benefit_market, to: :benefit_sponsorship

    embeds_many :benefit_packages,
      class_name: "::BenefitSponsors::BenefitPackages::BenefitPackage"

    validates_presence_of :effective_period, :open_enrollment_period, :recorded_service_areas, :recorded_rating_area, :recorded_sic_code

    add_observer ::BenefitSponsors::Observers::BenefitApplicationObserver.new, [:notifications_send]

    before_validation :pull_benefit_sponsorship_attributes
    after_create      :renew_benefit_package_assignments
    after_save        :notify_on_save
    after_create      :notify_on_create

    # Use chained scopes, for example: approved.effective_date_begin_on(start, end)
    scope :draft,               ->{ any_in(aasm_state: APPLICATION_DRAFT_STATES) }
    scope :draft_state,         ->{ where(aasm_state: :draft) }
    scope :approved,            ->{ any_in(aasm_state: APPLICATION_APPROVED_STATES) }

    scope :submitted,           ->{ any_in(aasm_state: APPROVED_STATES) }
    scope :exception,           ->{ any_in(aasm_state: APPLICATION_EXCEPTION_STATES) }
    scope :enrolling,           ->{ any_in(aasm_state: ENROLLING_STATES) }
    scope :enrolling_state,     ->{ where(aasm_state: :enrollment_open) }

    scope :enrollment_eligible,             ->{ any_in(aasm_state: ENROLLMENT_ELIGIBLE_STATES) }
    scope :enrollment_ineligible,           ->{ any_in(aasm_state: ENROLLMENT_INELIGIBLE_STATES) }
    scope :coverage_effective,              ->{ any_in(aasm_state: COVERAGE_EFFECTIVE_STATES) }
    scope :terminated,                      ->{ any_in(aasm_state: TERMINATED_STATES) }
    scope :imported,                        ->{ any_in(aasm_state: IMPORTED_STATES) }
    scope :non_canceled,                    ->{ not_in(aasm_state: TERMINATED_STATES) }
    scope :non_draft,                       ->{ not_in(aasm_state: APPLICATION_DRAFT_STATES) }
    scope :non_imported,                    ->{ not_in(aasm_state: IMPORTED_STATES) }

    scope :expired,                         ->{ any_in(aasm_state: EXPIRED_STATES) }

    # scope :is_renewing,                     ->{ where(:predecessor => {:$exists => true},
    #                                                   :aasm_state.in => APPLICATION_DRAFT_STATES + ENROLLING_STATES).order_by(:'created_at'.desc)
    #                                             }

    scope :effective_date_begin_on,         ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"effective_period.min".lte => compare_date )
                                                                                           }

    scope :effective_date_end_on,           ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"effective_period.max".lt => compare_date )
                                                                                           }

    scope :effective_period_cover,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                             :"effective_period.min".lte => compare_date,
                                                                                           :"effective_period.max".gte => compare_date)
                                                                                           }
    scope :future_effective_date,           ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"effective_period.min".gte => compare_date )
                                                                                           }
    scope :open_enrollment_period_cover,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                             :"opem_enrollment_period.min".lte => compare_date,
                                                                                           :"opem_enrollment_period.max".gte => compare_date)
                                                                                           }
    scope :open_enrollment_begin_on,        ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"open_enrollment_period.min".lte => compare_date)
                                                                                           }
    scope :open_enrollment_end_on,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"open_enrollment_period.max".lt => compare_date)
                                                                                           }
    scope :benefit_terminate_on,            ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                         :"terminated_on" => compare_date)
                                                                                         }
    scope :by_year,                          ->(compare_year = TimeKeeper.date_of_record.year) { where(
                                                                                                :"effective_period.min".gte => Date.new(compare_year, 1, 1),
                                                                                                :"effective_period.min".lte => Date.new(compare_year, 12, -1)
                                                                                              )}
    # TODO
    scope :published,                       ->{ any_in(aasm_state: PUBLISHED_STATES) }
    # scope :renewing,                        ->{ is_renewing } # Deprecate it in future

    # scope :by_effective_date_range,         ->(begin_on, end_on)  { where(:"effective_period.min".gte => begin_on, :"effective_period.min".lte => end_on) }
    # scope :renewing,                        ->{ any_in(aasm_state: RENEWING) }
    # scope :renewing_published_state,        ->{ any_in(aasm_state: RENEWING_APPROVED_STATE) }
    # scope :published_or_renewing_published, ->{ any_of([published.selector, renewing_published_state.selector]) }

    scope :published_benefit_applications_within_date_range, ->(begin_on, end_on) {
      where(
        "$and" => [
          {:aasm_state.in => APPROVED_STATES },
          {"$or" => [
             { :effective_period.min => {"$gte" => begin_on, "$lte" => end_on }},
             { :effective_period.max => {"$gte" => begin_on, "$lte" => end_on }}
           ]
           }
        ]
      )
    }

    scope :published_benefit_applications_by_date, ->(date) {
      where(
        "$and" => [
          {:aasm_state.in => APPROVED_STATES },
          {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
        ]
      )
    }

    scope :renewing, -> {
      where(:predecessor_id => {:$exists => true} )
    }

    scope :published_or_renewing_published, -> {
      warn "[Deprecated in the future]" unless Rails.env.test?
      where(
        "$or" => [
          {:aasm_state.in => APPROVED_STATES },
          {"$exists" => {:predecessor_id => true} }
        ]
      )
    }


    # Migration map for plan_year to benefit_application
    def matching_state_for(plan_year)
      plan_year_to_benefit_application_states_map[plan_year.aasm_state.to_sym]
    end

    def rate_schedule_date
      if benefit_sponsorship.source_kind == :mid_plan_year_conversion && predecessor.blank?
        end_on.prev_year + 1.day
      else
        start_on
      end
    end

    def sponsor_profile
      benefit_sponsorship.profile
    end

    # Setters/Getters

    # Set the benefit_application instance that preceded this one
    def predecessor=(benefit_application)
      if benefit_application.nil?
        write_attribute(:predecessor_id, nil)
      else
        raise ArgumentError.new("expected BenefitApplication") unless benefit_application.is_a? BenefitSponsors::BenefitApplications::BenefitApplication
        write_attribute(:predecessor_id, benefit_application._id)
      end
      @predecessor = benefit_application
    end

    def predecessor
      return nil if predecessor_id.blank?
      return @predecessor if defined? @predecessor
      @predecessor = benefit_sponsorship.benefit_applications_by(predecessor_id)
    end

    def successors
      return [] if benefit_sponsorship.blank?
      return @successors if defined? @successors
      @successors = benefit_sponsorship.benefit_application_successors_for(self)
    end

    def benefit_sponsor_catalog=(new_benefit_sponsor_catalog)
      raise ArgumentError.new("expected BenefitSponsorCatalog") unless new_benefit_sponsor_catalog.is_a? BenefitMarkets::BenefitSponsorCatalog
      write_attribute(:benefit_sponsor_catalog_id, new_benefit_sponsor_catalog._id)
      @benefit_sponsor_catalog = new_benefit_sponsor_catalog
    end

    def benefit_sponsor_catalog
      return nil if benefit_sponsor_catalog_id.blank?
      return @benefit_sponsor_catalog if defined? @benefit_sponsor_catalog
      @benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.find_by(benefit_sponsor_catalog_id)
    end

    def recorded_rating_area=(new_recorded_rating_area)
      if new_recorded_rating_area.nil?
        write_attribute(:recorded_rating_area_id, nil)
        @recorded_rating_area = nil
      else
        raise ArgumentError.new("expected RatingArea") unless new_recorded_rating_area.is_a? BenefitMarkets::Locations::RatingArea
        write_attribute(:recorded_rating_area_id, new_recorded_rating_area._id)
        @recorded_rating_area = new_recorded_rating_area
      end
      @recorded_rating_area
    end

    def recorded_rating_area
      return nil if recorded_rating_area_id.blank?
      return @recorded_rating_area if defined? @recorded_rating_area

      @recorded_rating_area = BenefitMarkets::Locations::RatingArea.find(recorded_rating_area_id)
    end

    def recorded_service_areas=(new_recorded_service_areas)
      if new_recorded_service_areas.nil? || new_recorded_service_areas == []
        write_attribute(:recorded_service_area_ids, [])
        @recorded_service_areas = []
      else
        raise ArgumentError.new("expected ServiceArea") if new_recorded_service_areas.any?{|service_area| !service_area.is_a? BenefitMarkets::Locations::ServiceArea}

        write_attribute(:recorded_service_area_ids, new_recorded_service_areas.map(&:_id))
        @recorded_service_areas = new_recorded_service_areas
      end
       @recorded_service_areas
    end

    def recorded_service_areas
      return [] if recorded_service_area_ids.blank?
      return @recorded_service_areas if defined? @recorded_service_areas
      @recorded_service_areas = BenefitMarkets::Locations::ServiceArea.find(recorded_service_area_ids)
    end

    def benefit_sponsor_catalog=(new_benefit_sponsor_catalog)
      raise ArgumentError.new("expected BenefitSponsorCatalog") unless new_benefit_sponsor_catalog.is_a? BenefitMarkets::BenefitSponsorCatalog
      write_attribute(:benefit_sponsor_catalog_id, new_benefit_sponsor_catalog._id)
      @benefit_sponsor_catalog = new_benefit_sponsor_catalog
    end

    def benefit_sponsor_catalog
      return nil if benefit_sponsor_catalog_id.blank?
      return @benefit_sponsor_catalog if defined? @benefit_sponsor_catalog
      @benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.find(benefit_sponsor_catalog_id)
    end

    def effective_period=(new_effective_period)
      effective_range = BenefitSponsors.tidy_date_range(new_effective_period, :effective_period)
      super(effective_range) unless effective_range.blank?
    end

    def open_enrollment_period=(new_open_enrollment_period)
      open_enrollment_range = BenefitSponsors.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
      super(open_enrollment_range) unless open_enrollment_range.blank?
    end

    def adjust_open_enrollment_date
      if TimeKeeper.date_of_record > open_enrollment_start_on && TimeKeeper.date_of_record < open_enrollment_end_on
        open_enrollment_period=((TimeKeeper.date_of_record.to_time.utc.beginning_of_day)..open_enrollment_end_on)
      end
    end

    def find_census_employees
      return @census_employees if defined? @census_employees
      @census_employees ||= CensusEmployee.benefit_application_assigned(self)
    end

    def active_census_employees
      find_census_employees.active
    end

    def assigned_census_employees_without_owner
      benefit_sponsorship.census_employees.active.non_business_owner
    end

    def start_on
      effective_period.begin unless effective_period.blank?
    end

    def end_on
      effective_period.end unless effective_period.blank?
    end

    def open_enrollment_start_on
      open_enrollment_period.min unless open_enrollment_period.blank?
    end

    def open_enrollment_end_on
      open_enrollment_period.max unless open_enrollment_period.blank?
    end

    def open_enrollment_length
      (open_enrollment_period.end - open_enrollment_period.begin).to_i
    end

    def is_submitted?
      PUBLISHED_STATES.include?(aasm_state)
    end

    # TODO: Refer to benefit_sponsorship instead of employer profile.
    def no_documents_uploaded?
      # benefit_sponsorship.employer_attestation.blank? || benefit_sponsorship.employer_attestation.unsubmitted?
      benefit_sponsorship.profile.employer_attestation.blank? || benefit_sponsorship.profile.employer_attestation.unsubmitted?
    end

    def effective_date
      start_on
    end

    def last_day_to_publish
      (start_on - 1.month).beginning_of_month + publish_due_day_of_month - 1.day
    end

    def publish_due_day_of_month
      is_renewing? ? benefit_market.configuration.renewal_application_configuration.pub_due_dom.days : benefit_market.configuration.initial_application_configuration.pub_due_dom.days
    end

    def may_publish?
      last_day_to_publish >= TimeKeeper.date_of_record
    end

    def default_benefit_group
      benefit_packages.detect(&:is_default)
    end

    def is_conversion?
      IMPORTED_STATES.include?(aasm_state)
    end

    def is_renewing?
      predecessor.present? && (APPLICATION_APPROVED_STATES + APPLICATION_DRAFT_STATES + ENROLLING_STATES + ENROLLMENT_ELIGIBLE_STATES + ENROLLMENT_INELIGIBLE_STATES).include?(aasm_state)
    end

    def is_renewal_enrolling?
      predecessor.present? && (ENROLLING_STATES).include?(aasm_state)
    end

    def open_enrollment_contains?(date)
      open_enrollment_period.cover?(date)
    end

    def issuers_offered_for(product_kind)
      benefit_packages.inject([]) do |issuers, benefit_package|
        issuers += benefit_package.issuers_offered_for(product_kind)
      end
    end

    def members_eligible_to_enroll
      return @members_eligible_to_enroll if defined? @members_eligible_to_enroll
      @members_eligible_to_enroll ||= active_census_employees
    end

    def members_eligible_to_enroll_count
      members_eligible_to_enroll.count
    end

    def waived_members
      return @waived_members if defined? @waived_members
      @waived_members ||= find_census_employees.waived
    end

    def waived_member_count
      waived_members.count
    end

    def enrolled_members
      return @enrolled_members if defined? @enrolled_members
      @enrolled_members ||= find_census_employees.covered
    end

    def enrolled_member_count
      enrolled_members.count
    end

    def enrolled_families
      return @enrolled_families if defined? @enrolled_families
      @enrolled_families ||= Family.enrolled_under_benefit_application(self)
    end

    def filter_enrolled_employees(employees_to_filter, total_enrolled)
      families_to_filter = employees_to_filter.collect{|census_employee| census_employee.family }.compact
      total_enrolled    -= families_to_filter
    end

    def hbx_enrollments
      @hbx_enrollments = [] if benefit_packages.size == 0
      @hbx_enrollments ||= HbxEnrollment.all_enrollments_under_benefit_application(self)
    end

    def cancel_enrollments
      hbx_enrollments.each do |enrollment|
        enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      end
    end

    def enrolled_non_business_owner_members
      return @enrolled_non_business_owner_members if defined? @enrolled_non_business_owner_members

      total_enrolled   = enrolled_families

      owner_employees  = active_census_employees.select{|ce| ce.is_business_owner}
      total_enrolled = filter_enrolled_employees(owner_employees, total_enrolled)

      waived_employees = active_census_employees.select{|ce| ce.waived?}
      total_enrolled = filter_enrolled_employees(waived_employees, total_enrolled)

      @enrolled_non_business_owner_members = total_enrolled
    end

    def enrolled_non_business_owner_count
      enrolled_non_business_owner_members.size
    end

    def all_enrolled_and_waived_member_count
      if active_census_employees.count <= Settings.aca.shop_market.small_market_active_employee_limit
        enrolled_families.size
      else
        0
      end
    end

    def minimum_enrolled_count
      (employee_participation_ratio_minimum * eligible_to_enroll_count).ceil
    end

    def additional_required_participants_count
      if total_enrolled_count < minimum_enrolled_count
        minimum_enrolled_count - total_enrolled_count
      else
        0.0
      end
    end


    # Reschedule the end date of open enrollment for this application.  The application must be in
    # open enrollment state already, or in an enrolling state that can transition to open enrollment.
    # Also, the new end date must be later than the existing end date, may not occur in the past, and
    # must precede the start of coverage
    #
    # @param [ Date ] new_end_date The date open enrollment for benefit selection will end
    # @return [ BenefitApplication ] Self, with the updated open enrollment period and application in
    # open enrollment state
    def extend_open_enrollment_period(new_end_date)
      if may_begin_open_enrollment? &&
          new_end_date < start_on &&
          [new_end_date, open_enrollment_end_on, TimeKeeper.date_of_record].max == new_end_date

        self.open_enrollment_period = open_enrollment_start_on..new_end_date
        begin_open_enrollment!
      end
      self
    end

    # Build a new [BenefitApplication] instance along with all associated child model instances, for the
    # benefit period immediately following this application's, applying the renewal settings
    # specified in the passed [BenefitSponsorCatalog]
    #
    # Service and rating areas are assigned from this application's BenefitSponsorship to pick up scenario
    # when Sponsor changes their primary office location during the previous enrollment effective period
    #
    # @param [ BenefitSponsorCatalog ] The catalog valid for the effective_period immediately following this
    # BenefitApplication instance's effective_period
    # @return [ BenefitApplication ] The built renewal application instance and submodels
    def renew(new_benefit_sponsor_catalog)
      if new_benefit_sponsor_catalog.effective_date != end_on + 1.day
        raise StandardError, "effective period must begin on #{end_on + 1.day}"
      end

      renewal_application = benefit_sponsorship.benefit_applications.new(
        fte_count:                fte_count,
        pte_count:                pte_count,
        msp_count:                msp_count,
        benefit_sponsor_catalog:  new_benefit_sponsor_catalog,
        predecessor:              self,
        effective_period:         new_benefit_sponsor_catalog.effective_period,
        open_enrollment_period:   new_benefit_sponsor_catalog.open_enrollment_period
      )

      renewal_application.pull_benefit_sponsorship_attributes

      new_benefit_sponsor_catalog.benefit_application = renewal_application
      new_benefit_sponsor_catalog.save

      benefit_packages.each do |benefit_package|
        new_benefit_package = renewal_application.benefit_packages.build
        benefit_package.renew(new_benefit_package)
      end

      renewal_application
    end

    def renew_benefit_package_assignments
      if is_renewing?
        benefit_packages.each do |benefit_package|
          benefit_package.renew_employee_assignments
        end

        default_benefit_package = benefit_packages.detect{|benefit_package| benefit_package.is_default }
        if benefit_sponsorship.census_employees.present?
          benefit_sponsorship.census_employees.non_terminated.benefit_application_unassigned(self).each do |census_employee|
            census_employee.assign_to_benefit_package(default_benefit_package, effective_period.min)
          end
        end
      end
    end

    def resolve_service_areas
      recorded_service_areas
    end

    def resolve_rating_area
      recorded_rating_area
    end

    def renew_benefit_package_members
      benefit_packages.each { |benefit_package| benefit_package.activate_benefit_group_assignments }
      benefit_packages.each { |benefit_package| benefit_package.renew_member_benefits } if is_renewing?
    end

    def transition_benefit_package_members
      transition_kind = BENEFIT_PACKAGE_MEMBERS_TRANSITION_MAP[aasm_state]
      return unless transition_kind.present?

      # :effectuate, :expire, :terminate, :cancel
      benefit_packages.each { |benefit_package| benefit_package.send("#{transition_kind}_member_benefits".to_sym) }
    end

    def refresh(new_benefit_sponsor_catalog)
      warn "[Deprecated] Instead use refresh_benefit_sponsor_catalog" unless Rails.env.test?
      refresh_benefit_sponsor_catalog(new_benefit_sponsor_catalog)
    end

    def refresh_benefit_sponsor_catalog(new_benefit_sponsor_catalog)
      if benefit_sponsorship_catalog != new_benefit_sponsor_catalog

        benefit_packages.each do |benefit_package|
          benefit_package.refresh(new_benefit_sponsor_catalog)
        end

        self.benefit_sponsor_catalog = new_benefit_sponsor_catalog
      end

      self
    end

    def send_employee_renewal_invites
      benefit_sponsorship.census_employees.non_terminated.each do |ce|
        ::Invitation.invite_renewal_employee!(ce)
      end
    end

    def send_employee_initial_enrollment_invites
      benefit_sponsorship.census_employees.non_terminated.each do |ce|
        ::Invitation.invite_initial_employee!(ce)
      end
    end

    def send_active_employee_invites
      benefit_sponsorship.census_employees.non_terminated.each do |ce|
        ::Invitation.invite_employee!(ce)
      end
    end

    def send_employee_invites
      if is_renewing?
        notify("acapi.info.events.plan_year.employee_renewal_invitations_requested", {:benefit_application_id => self.id.to_s})
      elsif enrollment_open?
        notify("acapi.info.events.plan_year.employee_initial_enrollment_invitations_requested", {:benefit_application_id => self.id.to_s})
      else
        notify("acapi.info.events.plan_year.employee_enrollment_invitations_requested", {:benefit_application_id => self.id.to_s})
      end
    end

    def accept_application
      adjust_open_enrollment_date
      transition_success = benefit_sponsorship.initial_application_approved! if benefit_sponsorship.may_approve_initial_application?
    end

    def recalc_pricing_determinations
      benefit_packages.each do |benefit_package|
        benefit_package.sponsored_benefits.each do |sb|
          cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_sponsorship, effective_period.min)
          sbenefit, _price, _cont = cost_estimator.calculate(sb, sb.reference_product, sb.product_package, build_new_pricing_determination: true)
        end
      end

      self.save
    end

    class << self

      def find(id)
        return nil if id.blank?
        sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_application_find(id).first

        if sponsorship.present?
          sponsorship.benefit_applications_by(id)
        end
      end
    end

    aasm do
      state :draft, initial: true
      state :imported             # Static state for seed application instances used to transfer Benefit Sponsors and members into the system

      state :approved             # Accepted - Application meets criteria necessary for sponsored members to shop for benefits.  Members may view benefits, but not enroll
      state :denied               # Rejected

      # TODO: Compare optional states with CCA values for Employer Attestation approval flow
      ## Begin optional states for exception processing
      state :pending              # queued for review or verification
      state :assigned             # assigned to case worker
      state :processing           # under consideration and determination
      state :reviewing            # determination under peer or supervisory review
      state :information_needed   # returned for supplementary information
      state :appealing            # request reversal of negative determination
      ## End optional states for exception processing

      # TODO: send_employee_invites - needs to be moved to observer pattern.
      state :enrollment_open, after_enter: [:recalc_pricing_determinations, :renew_benefit_package_members, :send_employee_invites] # Approved application has entered open enrollment period
      state :enrollment_closed
      state :enrollment_eligible    # Enrollment meets criteria necessary for sponsored members to effectuate selected benefits
      state :enrollment_ineligible  # open enrollment did not meet eligibility criteria

      state :active,     :after_enter => :transition_benefit_package_members  # Application benefit coverage is in-force
      state :terminated, :after_enter => :transition_benefit_package_members  # Coverage under this application is terminated
      state :expired,    :after_enter => :transition_benefit_package_members  # Non-published plans are expired following their end on date
      state :canceled,   :after_enter => :transition_benefit_package_members  # Application closed prior to coverage taking effect

      state :termination_pending
      state :suspended   # Coverage is no longer in effect. members may not enroll or change enrollments

      after_all_transitions :publish_state_transition

      event :import_application do
        transitions from: :draft, to: :imported
      end

      event :review_application do
        transitions from: :draft, to: :pending
      end

      # Returns plan to draft state (or) renewing draft for edit
      event :withdraw_pending do
        transitions from: :pending, to: :draft
      end

      # Employer requests review of invalid application determination
      event :request_eligibility_review do
        transitions from: :submitted, to: :pending #,  guard:  :is_within_review_period?
      end

      # Upon review, application ineligible status overturned and deemed eligible
      event :approve_application do
        transitions from: [:draft, :imported] + APPLICATION_EXCEPTION_STATES,  to: :approved
      end

      event :auto_approve_application do
        transitions from: [:draft, :imported] + APPLICATION_EXCEPTION_STATES,  to: :approved
      end

      event :submit_for_review do
        transitions from: :draft, to: :pending
      end

      # Upon review, submitted application ineligible status verified ineligible
      event :deny_application do
        transitions from: APPLICATION_EXCEPTION_STATES, to: :denied
      end

      event :begin_open_enrollment do
        transitions from:   [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_ineligible],
          to:     :enrollment_open
      end

      event :end_open_enrollment do
        transitions from:   :enrollment_open,
          to:     :enrollment_closed
      end

      event :approve_enrollment_eligiblity do
        transitions from:   :enrollment_closed,
          to:     :enrollment_eligible
      end

      event :deny_enrollment_eligiblity do
        transitions from:   :enrollment_closed,
          to:     :enrollment_ineligible
      end

      event :reverse_enrollment_eligibility do
        transitions from:   :enrollment_eligible,
          to:     :enrollment_closed
      end

      event :revert_application do
        transitions from:   [
          :approved, :denied,
          :enrollment_open, :enrollment_closed,
          :enrollment_eligible, :enrollment_ineligible,
          :active
        ] + APPLICATION_EXCEPTION_STATES,
          to:     :draft, :after => [:cancel_enrollments]
      end

      event :activate_enrollment do
        transitions from:   :enrollment_eligible,
          to:     :active
        transitions from:   APPLICATION_DRAFT_STATES + ENROLLING_STATES,
          to:     :canceled
      end

      event :simulate_provisional_renewal do
        transitions from: [:draft, :approved], to: :enrollment_open
      end

      event :expire do
        transitions from:   [:approved, :enrollment_open, :enrollment_eligible, :active],
          to:     :expired
      end

      # Enrollment processed stopped due to missing binder payment
      event :cancel do
        transitions from:   APPLICATION_DRAFT_STATES + ENROLLING_STATES + [:enrollment_ineligible],
          to:     :canceled
      end

      # Coverage disabled due to non-payment
      event :suspend_enrollment do
        transitions from: :active, to: :suspended
      end

      # Coverage terminated due to non-payment
      event :terminate_enrollment do
        transitions from: [:active, :suspended], to: :terminated
      end

      # Coverage reinstated
      event :reinstate_enrollment do
        transitions from: [:suspended, :terminated], to: :active #, after: :reset_termination_and_end_date
      end
    end

    # Notify BenefitSponsorship upon state change
    def publish_state_transition
      return unless benefit_sponsorship.present?
      benefit_sponsorship.application_event_subscriber(aasm)
    end

    def coverage_renewable?
      (APPROVED_STATES - [:approved]).include?(aasm_state)
    end

    # Listen for BenefitSponsorship state changes
    def benefit_sponsorship_event_subscriber(aasm)
      if (aasm.to_state == :binder_reversed) && may_reverse_enrollment_eligibility?
        reverse_enrollment_eligibility!
      end

      if (aasm.to_state == :initial_enrollment_eligible) && may_approve_enrollment_eligiblity?
        approve_enrollment_eligiblity!
      end

      if (aasm.to_state == :initial_enrollment_ineligible) && may_deny_enrollment_eligiblity?
        deny_enrollment_eligiblity!
      end

      if (aasm.to_state == :applicant && aasm.current_event == :cancel!)
        cancel! if enrollment_ineligible? && may_cancel?
      end
    end


    ### TODO FIX Move these methods to domain logic
            def employee_participation_ratio_minimum
              Settings.aca.shop_market.employee_participation_ratio_minimum.to_f
            end

            def eligible_for_export?
              return false if self.aasm_state.blank?
              return false if self.imported?
              return false if self.effective_period.blank?
              return true if self.enrollment_eligible? || self.active?
              self.terminated? || self.expired?
            end

            def enrollment_quiet_period
              if predecessor_id.present?
                # Weird things can happen when you extend open enrollment past
                # what would 'normally' be the quiet period end.  Can really
                # only happen on renewals.
                expected_renewal_transmission_deadline = renewal_quiet_period_end(start_on)
                deadline_because_of_open_enrollment_end = nil
                if open_enrollment_end_on.blank?
                  deadline_because_of_open_enrollment_end = expected_renewal_transmission_deadline
                else
                  deadline_because_of_open_enrollment_end = open_enrollment_end_on
                end
                quiet_period_start = open_enrollment_start_on
                quiet_period_end = [expected_renewal_transmission_deadline, deadline_because_of_open_enrollment_end].max
                TimeKeeper.start_of_exchange_day_from_utc(quiet_period_start)..TimeKeeper.end_of_exchange_day_from_utc(quiet_period_end)
              else
                if open_enrollment_end_on.blank?
                  prev_month = start_on.prev_month
                  quiet_period_start = Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on + 1)
                else
                  quiet_period_start = open_enrollment_end_on + 1.day
                end
                quiet_period_end = initial_quiet_period_end(start_on)
                TimeKeeper.start_of_exchange_day_from_utc(quiet_period_start)..TimeKeeper.end_of_exchange_day_from_utc(quiet_period_end)
              end
            end

            def initial_quiet_period_end(start_on)
              start_on + (Settings.aca.shop_market.initial_application.quiet_period.month_offset.months) + (Settings.aca.shop_market.initial_application.quiet_period.mday - 1).days
            end

            def renewal_quiet_period_end(start_on)
              start_on + (Settings.aca.shop_market.renewal_application.quiet_period.month_offset.months) + (Settings.aca.shop_market.renewal_application.quiet_period.mday - 1).days
            end
    ###


    def all_enrolled_members_count
      warn "[Deprecated] Instead use: all_enrolled_and_waived_member_count" unless Rails.env.production?
      all_enrolled_and_waived_member_count
    end

    def enrollment_ratio
      if members_eligible_to_enroll_count == 0
        0
      else
        ((all_enrolled_and_waived_member_count * 1.0)/ members_eligible_to_enroll_count)
      end
    end

    def total_enrolled_count
      warn "[Deprecated] Instead use: all_enrolled_and_waived_member_count" unless Rails.env.production?
      all_enrolled_and_waived_member_count
    end

    def non_business_owner_enrolled
      warn "[Deprecated] Instead use: enrolled_non_business_owner_members" unless Rails.env.production?
      enrolled_non_business_owner_members
    end

    def is_published? # Deprecate in future
      warn "[Deprecated] Instead use is_submitted?"  unless Rails.env.production?
      is_submitted?
    end

    def benefit_groups # Deprecate in future
      warn "[Deprecated] Instead use benefit_packages"  unless Rails.env.production?
      benefit_packages
    end

    def employees_are_matchable? # Deprecate in future
      warn "[Deprecated] Instead use is_submitted?"  unless Rails.env.production?
      is_submitted?
    end

    def waived
      warn "[Deprecated] Instead use: waived_members" unless Rails.env.production?
      waived_members
    end

    def waived_count
      warn "[Deprecated] Instead use: waived_member_count" unless Rails.env.production?
      waived_member_count
    end

    def covered
      warn "[Deprecated] Instead use: enrolled_members" unless Rails.env.production?
      enrolled_members
    end

    # Slightly different logic to count covered renewing to support correct progress bar
    def progressbar_covered_count
      find_census_employees.covered_progressbar.count
    end

    def covered_count
      warn "[Deprecated] Instead use: enrolled_member_count" unless Rails.env.production?
      enrolled_member_count
    end

    def eligible_to_enroll
      warn "[Deprecated] Instead use: members_eligible_to_enroll" unless Rails.env.production?
      members_eligible_to_enroll
    end

    def eligible_to_enroll_count
      warn "[Deprecated] Instead use: members_eligible_to_enroll_count" unless Rails.env.production?
      members_eligible_to_enroll_count
    end

    def employer_profile
      warn "[Deprecated] Instead use: sponsor_profile" unless Rails.env.production?
      sponsor_profile
    end

    # Assign local attributes derived from benefit_sponsorship parent instance
    def pull_benefit_sponsorship_attributes
      return unless benefit_sponsorship.present?
      return if self.start_on.blank?
      refresh_recorded_rating_area   unless recorded_rating_area.present?
      refresh_recorded_service_areas unless recorded_service_areas.size > 0
      refresh_recorded_sic_code      unless recorded_sic_code.present?
    end

    private

    def refresh_recorded_rating_area
      self.recorded_rating_area = benefit_sponsorship.rating_area_on(self.start_on)
    end

    def refresh_recorded_service_areas
      self.recorded_service_areas = benefit_sponsorship.service_areas_on(self.start_on)
    end

    def refresh_recorded_sic_code
      self.recorded_sic_code = benefit_sponsorship.sic_code
    end

    def validate_benefit_sponsorship_shared_attributes
      return unless benefit_sponsorship.present?
      errors.add(:recorded_rating_area,   "must match benefit_sponsorship rating area")   unless recorded_rating_area == benefit_sponsorship.rating_area
      errors.add(:recorded_service_areas, "must match benefit_sponsorship service areas") unless recorded_service_areas == benefit_sponsorship.service_areas
      errors.add(:recorded_sic_code,      "must match benefit_sponsorship sic code")      unless recorded_sic_code == benefit_sponsorship.sic_code
    end

    def log_message(errors)
      msg = yield.first
      (errors[msg[0]] ||= []) << msg[1]
    end

    # AASM states used in PlanYear as mapped to new BenefitApplication model
    def plan_year_to_benefit_application_states_map
      {
        :draft                    => :draft,
        :renewing_draft           => :draft,

        :submitted                => :submitted,
        :published                => :approved,
        :renewing_published       => :approved,

        :published_invalid        => :pending,
        :publish_pending          => :pending,  # Plan application as submitted has warnings
        :renewing_publish_pending => :pending,

        :eligibility_review       => :pending,  # Plan application was submitted with warning and is under review by HBX officials

        :enrolling                => :enrollment_open,
        :renewing_enrolling       => :enrollment_open,
        :enrollment_open          => :enrollment_open,

        :enrollment_closed        => :enrollment_closed,

        :enrolled                 => :enrollment_eligible,
        :renewing_enrolled        => :enrollment_eligible,

        :application_ineligible           => :enrollment_ineligible,
        :renewing_application_ineligible  => :enrollment_ineligible,

        :active                   => :active,
        :suspended                => :suspended,
        :terminated               => :terminated,
        :expired                  => :expired,
        :conversion_expired       => :expired,    # Conversion employers who did not establish eligibility in a timely manner
        :canceled                 => :canceled,
        :renewing_canceled        => :canceled,
        :termination_pending      => :termination_pending
      }
    end


  end
end
