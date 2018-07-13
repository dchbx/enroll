module SponsoredBenefits
  module BenefitCatalogs
    class BenefitCatalog
      include Mongoid::Document
      include Mongoid::Timestamps

      # Time periods when sponsors may initially offer, and subsequently renew, benefits
      #   :monthly - may start first of any month of the year and renews each year in same month
      #   :annual  - may start only on benefit market's annual effective date month and renews each year in same month
      #   :annual_with_midyear_initial - may start mid-year and renew at subsequent annual effective date month
      APPLICATION_INTERVAL_KINDS = [:monthly, :annual, :annual_with_midyear_initial]

      # Frequency at which sponsors may submit an initial or renewal application
      # Example application interval kinds:
      #   DC Individual Market, Congress:
      #     :application_interval_kind => :annual
      #   MA GIC
      #     :application_interval_kind => :annual_with_midyear_initial
      #   DC/MA SHOP Market:
      #     :application_interval_kind => :monthly
      field :application_interval_kind,  type: Symbol

      # Effective date range during which associated benefits may be offered by sponsors
      # Example application periods:
      #   DC Individual Market Initial & Renewal, Congress:
      #     :application_period => Date.new(2018,1,1)..Date.new(2018,12,31)
      #   MA GIC
      #     :application_period => Date.new(2018,7,1)..Date.new(2018,6,30)
      #   DC/MA SHOP Market:
      #     :application_period => Date.new(2018,1,1)..Date.new(2018,12,31)
      field :application_period,          type: Range

      # Length of time new members must wait before they're eligible to enroll
      field :probation_period_kinds,      type: Array,  default: SponsoredBenefits::PROBATION_PERIOD_KINDS

      field :title,                       type: String, default: ""
      field :description,                 type: String, default: ""

      belongs_to  :benefit_market,  class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

      # Entire geography covered by under this catalog
      has_and_belongs_to_many  :service_areas,  class_name: "SponsoredBenefits::Locations::ServiceArea"

      embeds_one  :sponsor_eligibility_policy,  class_name: "SponsoredBenefits::BenefitMarkets::SponsorEligibilityPolicy"
      embeds_one  :member_eligibility_policy,   class_name: "SponsoredBenefits::BenefitMarkets::MemberEligibilityPolicy"

      validates_presence_of :application_interval_kind, :application_period, :probation_period_kinds

      validates :application_interval_kind,
        inclusion:    { in: APPLICATION_INTERVAL_KINDS, message: "%{value} is not a valid application interval kind" },
        allow_nil:    false

      # validates :probation_period_kinds,
      #   inclusion:    { in: SponsoredBenefits::PROBATION_PERIOD_KINDS, message: "%{value} is not a valid probation period kind" },
      #   allow_nil:    false

      scope :by_application_date,     ->(date){ where(:"application_period.min".gte => date, :"application_period.max".lte => date) }

      index({ "application_period.min" => 1, "application_period.max" => 1 })


      def products
        return @products if defined?(@products)
        @products = SponsoredBenefits::BenefitCatalogs::Product.find_by_benefit_catalog(self)
      end

      def application_period_cover?(compare_date)
        application_period.cover?(compare_date)
      end

      def effective_period_on(effective_date)
        effective_date = effective_date.beginning_of_month
        return unless application_period_cover?(effective_date)

        case application_interval_kind
        when :monthly
          effective_date..(effective_date + 1.year - 1.day)
        when :annual_with_midyear_initial
          effective_date..(effective_date + 1.year - 1.day)
        when :annual 
          application_period
        end
      end

      def open_enrollment_period_on(effective_date)
        effective_date = effective_date.beginning_of_month
        return unless application_period_cover?(effective_date)

        earliest_begin_date = effective_date - benefit_market.open_enrollment_maximum_length
        prior_month = effective_date - 1.month

        begin_on = Date.new(earliest_begin_date.year, earliest_begin_date.month, 1)
        end_on   = Date.new(prior_month.year, prior_month.month, @benefit_market.open_enrollment_end_on_day_of_month)

        begin_on..end_on
      end


      def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
        if use_grace_period
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
        else
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
        end

        open_enrollment_end_on_day = Settings.aca.shop_market.open_enrollment.monthly_end_on
        open_enrollment_end_on_day - minimum_length
      end





    end
  end
end
