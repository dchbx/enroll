module SponsoredBenefits
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorship, class_name: "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"

      delegate :sic_code, to: :benefit_sponsorship
      delegate :rating_area, to: :benefit_sponsorship
      delegate :census_employees, to: :benefit_sponsorship
      delegate :plan_design_organization, to: :benefit_sponsorship

     ### Deprecate -- use effective_period attribute
      # field :start_on, type: Date
      # field :end_on, type: Date

      # The date range when this application is active
      field :effective_period,        type: Range

      ### Deprecate -- use open_enrollment_period attribute
      # field :open_enrollment_start_on, type: Date
      # field :open_enrollment_end_on, type: Date

      # The date range when members may enroll in benefit products
      field :open_enrollment_period,  type: Range

      # Populate when enrollment is terminated prior to open_enrollment_period.end
      # field :terminated_early_on, type: Date

      # field :sponsorable_id, type: String
      # field :rosterable_id, type: String
      # field :broker_id, type: String
      # field :kind, type: :symbol

      # has_one :rosterable, as: :rosterable

      embeds_many :benefit_groups, class_name: "SponsoredBenefits::BenefitApplications::BenefitGroup", cascade_callbacks: true

      # embeds_many :benefit_packages, as: :benefit_packageable, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage"
      # accepts_nested_attributes_for :benefit_packages

      # ## Override with specific benefit package subclasses
      #   embeds_many :benefit_packages, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage", cascade_callbacks: true
      #   accepts_nested_attributes_for :benefit_packages
      # ##

      validates_presence_of :effective_period, :open_enrollment_period, :message => "is missing"
      # validate :validate_application_dates

      validate :open_enrollment_date_checks

      #
      # Are these correct? I don't think you can move an embedded object just by changing an id?
      #
      # def benefit_sponsor=(new_sponsor)
      #   self.sponsorable_id = new_sponsor.id
      # end
      #
      # BrokerAgencyProfile embeds this entire chain - this can't be the way we adjust it
      #
      # def broker=(new_broker)
      #   self.broker_id = new_broker.id
      # end


      ## Stub for BQT
      def estimate_group_size?
        true
      end

      def effective_period=(new_effective_period)
        effective_range = SponsoredBenefits.tidy_date_range(new_effective_period, :effective_period)
        write_attribute(:effective_period, effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = SponsoredBenefits.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        write_attribute(:open_enrollment_period, open_enrollment_range) unless open_enrollment_range.blank?
      end

      def start_on
        effective_period.begin
      end

      def end_on
        effective_period.end
      end

      def open_enrollment_begin_on
        open_enrollment_period.begin
      end

      def open_enrollment_end_on
        open_enrollment_period.end
      end

      def open_enrollment_completed?
        open_enrollment_period.blank? ? false : (::TimeKeeper.date_of_record > open_enrollment_period.end)
      end

      # Application meets criteria necessary for sponsored group to shop for benefits
      def is_open_enrollment_eligible?
      end

      # Application meets criteria necessary for sponsored group to effectuate selected benefits
      def is_coverage_effective_eligible?
      end

      # def employer_profile
      #   benefit_sponsorship.benefit_sponsorable
      # end

      def default_benefit_group
        benefit_groups.detect(&:default)
      end

      def minimum_employer_contribution
        unless benefit_groups.size == 0
          benefit_groups.map do |benefit_group|
            if benefit_group.sole_source?
              OpenStruct.new(:premium_pct => 100)
            else
              benefit_group.relationship_benefits.select do |relationship_benefit|
                relationship_benefit.relationship == "employee"
              end.min_by do |relationship_benefit|
                relationship_benefit.premium_pct
              end
            end
          end.map(&:premium_pct).first
        end
      end

      def to_benefit_sponsors_benefit_application(organization)
        return unless(benefit_sponsorship.present? && effective_period.present? && open_enrollment_period.present?)
        raise "Invalid number of benefit_groups: #{benefit_groups.size}" if benefit_groups.size != 1

        new_benefit_sponsorship = build_benefit_sponsors_benefit_sponsorship_if_needed(organization, benefit_sponsorship)

        new_benefit_application = new_benefit_sponsorship.benefit_applications.new(
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period
        )
        set_predecessor_applications_if_present(new_benefit_sponsorship, new_benefit_application)
        new_benefit_application.pull_benefit_sponsorship_attributes
        if new_benefit_application.valid? && new_benefit_sponsorship.valid?# && new_benefit_application.save
          update_benefit_sponsor_catalog(new_benefit_application, new_benefit_sponsorship)
          add_benefit_packages(new_benefit_application)
        end

        new_benefit_application
      end

      def set_predecessor_applications_if_present(new_benefit_sponsorship, new_benefit_application)
        predecessor_applications = new_benefit_sponsorship.benefit_applications.where(:"effective_period.max" => new_benefit_application.effective_period.min.to_date.prev_day, :aasm_state.in=> [:active, :terminated, :expired, :imported])
        if predecessor_applications.present?
          if predecessor_applications.count < 2
            new_benefit_application.predecessor_id = predecessor_applications.first.id
          elsif predecessor_applications.where(:"effective_period.max" => Date.new(2018,7,31)).count == 2  # exception case for 8/1 conversion
            new_benefit_application.predecessor_id = predecessor_applications.where(aasm_state: :imported).first.id
          else
            new_benefit_application.predecessor_id = predecessor_applications.first.id
          end
        end
      end

      def add_benefit_packages(new_benefit_application)
        benefit_groups.each do |benefit_group|
          importer = BenefitSponsors::Importers::BenefitPackageImporter.call(new_benefit_application, sanitize_benefit_group_attrs(benefit_group))
          if importer.benefit_package
            set_predecessor_for_benefit_package(new_benefit_application, importer.benefit_package)
            importer.benefit_package.save!
          end
        end
      end

      def build_benefit_sponsors_benefit_sponsorship_if_needed(organization, old_benefit_sponsorship)
        if organization.active_benefit_sponsorship.present?
          organization.active_benefit_sponsorship
        else
          organization.benefit_sponsorships.new
          #TODO: Update data from sponsored_benefit benefit sponsorship model.
        end
      end

      def set_predecessor_for_benefit_package(benefit_application, benefit_package)
        return unless benefit_application.predecessor_id.present?
        predecessor_application = benefit_application.predecessor
        predecessor_benefit_packages = benefit_application.predecessor.benefit_packages

        if predecessor_benefit_packages.count < 2
          benefit_package.predecessor_id  = benefit_application.predecessor.benefit_packages.first.id
          return
        end

        new_package_hios_id = benefit_package.health_sponsored_benefit.products(benefit_application.effective_period.min).map(&:hios_id)
        predecessor_benefit_packages.each do |predecessor_package|
          predecessor_package_hios_id = predecessor_package.health_sponsored_benefit.products(predecessor_application.effective_period.min).map(&:hios_id)
          if ((new_package_hios_id.size == predecessor_package_hios_id.size) && ((new_package_hios_id && predecessor_package_hios_id).size == new_package_hios_id.size))
            benefit_package.predecessor_id  = predecessor_package.id
          end
        end
      end

      def sanitize_benefit_group_attrs(benefit_group)
        attributes = benefit_group.attributes.slice(
          :title, :description, :created_at, :updated_at, :is_active, :effective_on_kind, :effective_on_offset,
          :plan_option_kind, :relationship_benefits, :dental_relationship_benefits
          )

        attributes[:is_default] = benefit_group.default
        attributes[:reference_plan_hios_id] = benefit_group.reference_plan.hios_id
        attributes[:dental_reference_plan_hios_id] = benefit_group.dental_reference_plan.hios_id if benefit_group.is_offering_dental?
        attributes[:composite_tier_contributions] = benefit_group.composite_tier_contributions.inject([]) do |contributions, tier|
          contributions << {
            relationship: tier.composite_rating_tier,
            offered: tier.offered,
            premium_pct: tier.employer_contribution_percent,
            estimated_tier_premium: tier.estimated_tier_premium
          }
        end
        attributes
      end

      class << self
        def calculate_start_on_dates
          start_on = if TimeKeeper.date_of_record.day > open_enrollment_minimum_begin_day_of_month(true)
            TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
          else
            TimeKeeper.date_of_record.prev_month.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
          end

          end_on = TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
          dates = (start_on..end_on).select {|t| t == t.beginning_of_month}
        end

        def calculate_start_on_options
          calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
        end

        def enrollment_timetable_by_effective_date(effective_date)
          effective_date            = effective_date.to_date.beginning_of_month
          effective_period          = effective_date..(effective_date + 1.year - 1.day)
          open_enrollment_period    = open_enrollment_period_by_effective_date(effective_date)
          prior_month               = effective_date - 1.month
          binder_payment_due_on     = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)

          open_enrollment_minimum_day     = open_enrollment_minimum_begin_day_of_month
          open_enrollment_period_minimum  = Date.new(prior_month.year, prior_month.month, open_enrollment_minimum_day)..open_enrollment_period.end

          {
              effective_date: effective_date,
              effective_period: effective_period,
              open_enrollment_period: open_enrollment_period,
              open_enrollment_period_minimum: open_enrollment_period_minimum,
              binder_payment_due_on: binder_payment_due_on,
            }
        end

        def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
          if use_grace_period
            minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
          else
            minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
          end

          open_enrollment_end_on_day = Settings.aca.shop_market.open_enrollment.monthly_end_on
          open_enrollment_end_on_day - minimum_length

          minimum_day = open_enrollment_end_on_day - minimum_length
           if minimum_day > 0
             minimum_day
           else
             1
           end
        end


        # TODOs
        ## handle late rate scenarios where partial or no benefit product plan/rate data exists for effective date
        ## handle midyear initial enrollments for annual fixed enrollment periods
        def effective_period_by_date(given_date = TimeKeeper.date_of_record, use_grace_period = false)
          given_day_of_month    = given_date.day
          next_month_start      = given_date.end_of_month + 1.day
          following_month_start = next_month_start + 1.month

          if use_grace_period
            last_day = open_enrollment_minimum_begin_day_of_month(true)
          else
            last_day = open_enrollment_minimum_begin_day_of_month
          end

          if given_day_of_month > last_day
            following_month_start..(following_month_start + 1.year - 1.day)
          else
            next_month_start..(next_month_start + 1.year - 1.day)
          end
        end


        def open_enrollment_period_by_effective_date(effective_date)
          earliest_begin_date = effective_date + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
          prior_month = effective_date - 1.month

          begin_on = Date.new(earliest_begin_date.year, earliest_begin_date.month, 1)
          end_on   = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on)
          begin_on..end_on
        end


        def find(id)
          application = nil
          Organizations::PlanDesignOrganization.where(:"plan_design_profile.benefit_sponsorships.benefit_applications._id" => BSON::ObjectId.from_string(id)).each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            sponsorships.each do |sponsorship|
              application = sponsorship.benefit_applications.detect { |benefit_application| benefit_application._id == BSON::ObjectId.from_string(id) }
              break if application.present?
            end
          end
          application
        end
      end

      def open_enrollment_date_checks
        return if effective_period.blank? || open_enrollment_period.blank?

        if effective_period.begin.mday != effective_period.begin.beginning_of_month.mday
          errors.add(:effective_period, "start date must be first day of the month")
        end

        if effective_period.end.mday != effective_period.end.end_of_month.mday
          errors.add(:effective_period, "must be last day of the month")
        end

        if effective_period.end > effective_period.begin.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
          errors.add(:effective_period, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
        end

        if open_enrollment_period.end > effective_period.begin
          errors.add(:effective_period, "start date can't occur before open enrollment end date")
        end

        if open_enrollment_period.end < open_enrollment_period.begin
          errors.add(:open_enrollment_period, "can't occur before open enrollment start date")
        end

        if open_enrollment_period.begin < (effective_period.begin - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          errors.add(:open_enrollment_period.begin, "can't occur earlier than 60 days before start date")
        end

        if open_enrollment_period.end > (open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
        end

        ## Leave this validation disabled in the BQT??
        # if (effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
        #   errors.add(:effective_period, "may not start application before " \
        #              "#{(effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period.begin} effective date")
        # end
      end

      private


      def update_benefit_sponsor_catalog(benefit_application, benefit_sponsorship)
        #update benefit sponsor catalog details
        benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.resolve_service_areas, benefit_application.effective_period.begin)
        catalog = benefit_application.benefit_sponsor_catalog
        catalog.benefit_application = benefit_application
        catalog.save
      end

    end
  end
end
