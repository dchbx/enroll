Mongoid::Migration.say_with_time("Load MA Benefit Market Catalogs") do

  site = BenefitSponsors::Site.where(site_key: "#{Settings.site.subdomain}").first

  benefit_market = BenefitMarkets::BenefitMarket.where(:site_urn => Settings.site.key, kind: :aca_shop).first

  [2017, 2018].each do |calender_year|

    puts "Creating Benefit Market Catalog for #{calender_year}"
    benefit_market_catalog = benefit_market.benefit_market_catalogs.create!({
      title: "#{Settings.aca.state_abbreviation} #{Settings.site.short_name} SHOP Benefit Catalog",
      application_interval_kind: :monthly,
      application_period: Date.new(calender_year,1,1)..Date.new(calender_year,12,31),
      probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
    })

    composite_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Composite Contribution Model").first.create_copy_for_embedding
    composite_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA Composite Price Model").first.create_copy_for_embedding

    list_bill_contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA List Bill Shop Contribution Model").first.create_copy_for_embedding
    list_bill_pricing_model = BenefitMarkets::PricingModels::PricingModel.where(:name => "MA List Bill Shop Pricing Model").first.create_copy_for_embedding


    def products_for(product_package, calender_year)
      puts "Found #{BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).count} products for #{calender_year} #{product_package.package_kind.to_s}"
      BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).collect { |prod| prod.create_copy_for_embedding }
    end

    puts "Creating Product Packages..."
    product_package = benefit_market_catalog.product_packages.new({
      benefit_kind: :aca_shop, product_kind: :health, title: 'Single Issuer',
      package_kind: :single_issuer,
      application_period: benefit_market_catalog.application_period,
      contribution_model: list_bill_contribution_model,
      pricing_model: list_bill_pricing_model
    })

    product_package.products = products_for(product_package, calender_year)
    product_package.save! if product_package.valid?

    product_package = benefit_market_catalog.product_packages.new({
      benefit_kind: :aca_shop, product_kind: :health, title: 'Metal Level',
      package_kind: :metal_level,
      application_period: benefit_market_catalog.application_period,
      contribution_model: list_bill_contribution_model,
      pricing_model: list_bill_pricing_model
    })

    product_package.products = products_for(product_package, calender_year)
    product_package.save! if product_package.valid?

    product_package = benefit_market_catalog.product_packages.new({
      benefit_kind: :aca_shop, product_kind: :health, title: 'Single Product',
      package_kind: :single_product,
      application_period: benefit_market_catalog.application_period,
      contribution_model: composite_contribution_model,
      pricing_model: composite_pricing_model
    })

    product_package.products = products_for(product_package, calender_year)
    product_package.save! if product_package.valid?
  end
end
