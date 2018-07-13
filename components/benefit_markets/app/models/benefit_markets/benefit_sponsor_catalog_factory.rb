module BenefitMarkets
  class BenefitSponsorCatalogFactory

    attr_reader :benefit_market_catalog, :benefit_sponsor_catalog

    def self.call(effective_date, benefit_market_catalog, service_areas=nil)
      new(effective_date, benefit_market_catalog, service_areas).benefit_sponsor_catalog
    end

    def initialize(effective_date, benefit_market_catalog, service_areas=nil)
      @benefit_market_catalog = benefit_market_catalog
      @effective_date   = effective_date

      @benefit_sponsor_catalog = ::BenefitMarkets::BenefitSponsorCatalog.new
      @benefit_sponsor_catalog.effective_date = effective_date
      @benefit_sponsor_catalog.effective_period = benefit_market_catalog.effective_period_on(effective_date)
      @benefit_sponsor_catalog.open_enrollment_period = benefit_market_catalog.open_enrollment_period_on(effective_date)
      @benefit_sponsor_catalog.service_areas = service_areas

      add_probation_period_kinds
      add_sponsor_market_policy
      add_member_market_policy
      add_product_packages
    end

    def add_probation_period_kinds
      benefit_sponsor_catalog.probation_period_kinds = benefit_market_catalog.probation_period_kinds
    end

    def add_sponsor_market_policy
      benefit_sponsor_catalog.sponsor_market_policy = benefit_market_catalog.sponsor_market_policy
    end

    def add_member_market_policy
      benefit_sponsor_catalog.member_market_policy = benefit_market_catalog.member_market_policy
    end

    def add_product_packages
      # TODO: Optimize the code
      # benefit_market_catalog.product_packages.collect do |product_package|
      #   # product_package.products = product_package.benefit_market_products_available_for(@service_area, @effective_date)
      # end

      benefit_sponsor_catalog.product_packages = benefit_market_catalog.product_packages.collect do |product_package| 
        construct_sponsor_product_package(product_package)
      end
    end

    def construct_sponsor_product_package(market_product_package)
      product_package = BenefitMarkets::Products::ProductPackage.new(
        title: market_product_package.title,
        description: market_product_package.description,
        product_kind: market_product_package.product_kind,
        benefit_kind: market_product_package.benefit_kind, 
        package_kind: market_product_package.package_kind
      )

      product_package.application_period = benefit_sponsor_catalog.effective_period
      product_package.contribution_model = market_product_package.contribution_model.create_copy_for_embedding
      product_package.pricing_model = market_product_package.pricing_model.create_copy_for_embedding
      product_package.products = market_product_package.load_embedded_products(benefit_sponsor_catalog.service_areas, @effective_date)
      product_package
    end

    def benefit_sponsor_catalog
      @benefit_sponsor_catalog
    end
  end
end




