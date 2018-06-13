module SponsoredBenefits
  class BenefitMarketServicePeriod
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_market, class_name: "SponsoredBenefits::BenefitMarket"

    ## BenefitMarket's Annual Effective Periods
    # DC & MA SHOP: Jan-Dec
    # DC IVL: Jan-Dec
    # MA IVL: July-June
    # GIC: July-June 

    field :open_enrollment_period,  type: Range
    field :effective_period,  type: Range

    has_many :geographic_rating_areas
    has_and_belongs_to_many :benefit_products, class_name: "SponsoredBenefits::BenefitProducts::BenefitProduct"


    def open_enrollment_begin_on
      open_enrollment_period.begin
    end

    def open_enrollment_end_on
      open_enrollment_period.end
    end

    def issuer_profiles
      benefit_products.uniq { |bp| bp.issuer_profile } || []
    end

    def benefit_products_by_kind(benefit_product_kind)
      benefit_products.collect { |bp| bp if bp.benefit_product_kind == benefit_product_kind } || []
    end

  end
end
