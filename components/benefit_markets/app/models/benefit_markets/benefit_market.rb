# BenefitMarket is a marketplace where BenefitSponsors choose benefit products to offer to their members.  Market behaviors and products
# are governed by law, along with rules and policies of the market owner.  ACA Individual market and ACA SHOP market are two example market kinds.
# BenefitMarket owners publish and refresh benefit products on a periodic basis using BenefitCatalogs
module BenefitMarkets
  class BenefitMarket
    include Mongoid::Document
    include Mongoid::Timestamps

    attr_reader :contact_center_profile

    field :site_urn,    type: String
    field :kind,        type: Symbol #, default: :aca_individual  # => :aca_shop
    field :title,       type: String, default: "" # => DC Health Link SHOP Market
    field :description, type: String, default: ""

    belongs_to  :site, class_name: "::BenefitSponsors::Site"
    # has_many    :benefit_sponsorships,  class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
    has_many    :benefit_market_catalogs,
                class_name: "BenefitMarkets::BenefitMarketCatalog"

    embeds_one :configuration, class_name: "BenefitMarkets::Configurations::Configuration"
    embeds_one :contact_center_setting, class_name: "BenefitMarkets::ContactCenterConfiguration",
                                        autobuild: true

    validates_presence_of :configuration #, :contact_center_setting
    validates_presence_of :site_urn, :kind, :title, :description

    validates :kind,
      inclusion:  { in: BenefitMarkets::BENEFIT_MARKET_KINDS, message: "%{value} is not a valid market kind" },
      allow_nil:  false

    index({ kind:  1 })

    delegate :enforce_employer_attestation, to: :configuration, allow_nil: true

    # BenefitMarketCatalogs may not overlap application_periods
    def add_benefit_market_catalog(new_benefit_market_catalog)
      application_period_is_covered = benefit_market_catalogs.detect do | catalog |
        catalog.application_period.cover?(new_benefit_market_catalog.application_period.min) ||
        catalog.application_period.cover?(new_benefit_market_catalog.application_period.max)
      end
      benefit_market_catalogs << new_benefit_market_catalog unless application_period_is_covered
    end

    def renew_benefit_market_catalog(benefit_market_catalog)
    end

    # Catalogs with benefit products currently available for purchase
    def benefit_market_catalog_effective_on(date = ::TimeKeeper.date_of_record)
      benefit_market_catalog = benefit_market_catalogs.detect { |catalog| catalog.application_period_cover?(date)}
      if benefit_market_catalog.blank?
        raise InvalidEffectiveDateError, "benefit_market_catalog not found for effective date: #{date}"
      end
      benefit_market_catalog
    end

    def benefit_sponsor_catalog_for(service_areas, effective_date = ::TimeKeeper.date_of_record)
      benefit_catalog = benefit_market_catalog_effective_on(effective_date)
      BenefitSponsorCatalogFactory.call(effective_date, benefit_catalog, service_areas)
    end

    # Calculate available effective dates periods using passed date
    def available_effective_dates_for(base_date = ::Timekeeper.date_of_record)
      start_on = if TimeKeeper.date_of_record.day > open_enrollment_minimum_begin_day_of_month
        TimeKeeper.date_of_record.beginning_of_month + open_enrollment_maximum_length
      else
        TimeKeeper.date_of_record.prev_month.beginning_of_month + open_enrollment_maximum_length
      end

      end_on = TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
      (start_on..end_on).select {|t| t == t.beginning_of_month}
    end

    def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
      if use_grace_period
        configuration.open_enrollment_end_on_montly - configuration.open_enrollment_grace_period_length_days_min
      else
        configuration.open_enrollment_end_on_montly - configuration.open_enrollment_days_min
      end
    end

    def open_enrollment_maximum_length
      # Settings.aca.shop_market.open_enrollment.maximum_length.months.months
      configuration.open_enrollment_months_max.months
    end

    def open_enrollment_end_on_day_of_month
      configuration.open_enrollment_end_on_montly
    end

    def open_enrollment_minimum_length_days
      configuration.open_enrollment_adv_days_min
    end

    def open_enrollment_grace_period_minimum_length_days
      configuration.open_enrollment_minimum_length_days
    end

    private

    def reset_configuration_attributes
      return unless kind.present? && BenefitMarkets::BENEFIT_MARKET_KINDS.include?(kind)
      # TODO: Fix configuration
      klass_name = configuration_class_name
      self.configuration = klass_name.constantize.new
    end

    # Configuration setting model is automatically associated based on "kind" attribute value
    def configuration_class_name
      config_klass = "#{kind.to_s}_configuration".camelcase
      namespace_for(self.class) + "::BenefitMarkets::Configurations::#{config_klass}"
    end

    # Isolate the namespace portion of the passed class
    def namespace_for(klass)
      klass_name = klass.to_s.split("::")
      klass_name.slice!(-1) || []
      klass_name.join("::")
    end

  end
end
