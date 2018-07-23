module BenefitMarkets
  class BenefitMarketCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

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

    # Sponsor choices for length of time new members must wait before they're eligible to enroll
    field :probation_period_kinds,      type: Array, default: []

    field :title,                       type: String, default: ""
    field :description,                 type: String, default: ""

    delegate    :kind, to: :benefit_market, prefix: true

    belongs_to  :benefit_market,
                class_name: "BenefitMarkets::BenefitMarket"

    embeds_one  :sponsor_market_policy,
                class_name: "::BenefitMarkets::MarketPolicies::SponsorMarketPolicy"
    embeds_one  :member_market_policy,
                class_name: "::BenefitMarkets::MarketPolicies::MemberMarketPolicy"
    embeds_many :product_packages, as: :packagable,
                class_name: "::BenefitMarkets::Products::ProductPackage"

    # Entire geography covered by under this catalog
    has_and_belongs_to_many  :service_areas,
                              class_name: "::BenefitMarkets::Locations::ServiceArea"


    validates_presence_of :benefit_market, :application_interval_kind, :application_period, :probation_period_kinds

    validates :application_interval_kind,
      inclusion:    { in: BenefitMarkets::APPLICATION_INTERVAL_KINDS, message: "%{value} is not a valid application interval kind" },
      allow_nil:    false

    validate :validate_probation_periods
    validate :unique_application_period_range

    scope :by_application_date,     ->(date){ where(:"application_period.min".lte => date, :"application_period.max".gte => date) }

    index({ "application_period.min" => 1, "application_period.max" => 1 })

    def benefit_sponsor_catalog_for(service_areas: nil, effective_date: ::TimeKeeper.date_of_record)
      BenefitSponsorCatalogFactory.call(effective_date, self, service_areas)
    end

    # Remove this and delegate properly once Products are implemented
    def product_market_kind
      bmk = benefit_market.kind.to_s
      kind_map = {
        "aca_shop" => "shop",
        "aca_individiaul" => "individual"
      }
      kind_map[bmk]
    end

    # Remove this and delegate properly once Products are implemented
    def product_active_year
      application_period.begin.year
    end

    # All ProductPackages that Sponsor is eligible to offer to members
    def product_packages_for(service_areas, effective_date)
      product_packages.select{|product_package| product_package.is_available_for?(service_areas, effective_date) }
    end

    def issuers_for(benefit_application)
    end

    def product_packages_by_benefit_kind() # => health, dental
    end

    def benefit_types_for(benefit_application)
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
      end_on   = Date.new(prior_month.year, prior_month.month, benefit_market.open_enrollment_end_on_day_of_month)

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

    private

    def unique_application_period_range
      return false unless application_period.present?

      begin_date_covered  = self.class.by_application_date(application_period.min).where(:id.ne => id).count > 0
      end_date_covered    = self.class.by_application_date(application_period.max).where(:id.ne => id).count > 0

      if begin_date_covered || end_date_covered
        errors.add(:application_period, "already exists for dates: #{application_period}")
        false
      else
        true
      end
    end

    def validate_probation_periods
      return false if probation_period_kinds.blank?
      probation_period_kinds.each do |ppk|
        unless ::BenefitMarkets::PROBATION_PERIOD_KINDS.include?(ppk)
          errors.add(:probation_period_kinds, "#{ppk} is not a valid probation period kind")
        end
      end
      true
    end

  end
end
