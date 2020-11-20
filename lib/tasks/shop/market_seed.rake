namespace :shop do
  desc "Load ACA SHOP & FEHB markets"
  task :market_seed => :environment do

    puts ":::: Creating markets, pricing models, contribution units ::::"

    site = BenefitSponsors::Site.all.first
    site_key = Settings.site.key
    state = site_key.upcase.to_s
    current_year = TimeKeeper.date_of_record.year
    years = [current_year - 1, current_year, current_year + 1]

    shop_market = BenefitMarkets::BenefitMarket.create!(
      site_urn: site_key, kind: :aca_shop, title: "ACA SHOP", description: "#{state} ACA Shop Market", site_id: site.id, configuration: BenefitMarkets::Configurations::AcaShopConfiguration.new
    )

    fehb_market = BenefitMarkets::BenefitMarket.create!(
      site_urn: site_key, kind: :fehb, title: "ACA SHOP", description: "#{state} ACA Shop Market", site_id: site.id, configuration: BenefitMarkets::Configurations::AcaShopConfiguration.new
    )


    pricing_model = BenefitMarkets::PricingModels::PricingModel.new(
      name: "#{state} Shop Simple List Bill Pricing Model",
      price_calculator_kind: "::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator",
      product_multiplicities: [:single],
      pricing_units: [
        BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
          name: "employee", display_name: "Employee", order: 0, _type: "BenefitMarkets::PricingModels::RelationshipPricingUnit", discounted_above_threshold: nil, eligible_for_threshold_discount: false
        ),
        BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
          name: "spouse", display_name: "Spouse", order: 1, _type: "BenefitMarkets::PricingModels::RelationshipPricingUnit", discounted_above_threshold: nil, eligible_for_threshold_discount: false
        ),
        BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
          name: "dependent", display_name: "Dependents", order: 2, _type: "BenefitMarkets::PricingModels::RelationshipPricingUnit", discounted_above_threshold: 4, eligible_for_threshold_discount: true
        )
      ],
      member_relationships: [
        BenefitMarkets::PricingModels::MemberRelationship.new(
          relationship_name: :employee, relationship_kinds: ["self"], age_threshold: nil, age_comparison: nil, disability_qualifier: nil
        ),
        BenefitMarkets::PricingModels::MemberRelationship.new(
          relationship_name: :spouse, relationship_kinds: ["spouse", "life_partner", "domestic_partner"], age_threshold: nil, age_comparison: nil, disability_qualifier: nil
        ),
        BenefitMarkets::PricingModels::MemberRelationship.new(
          relationship_name: :dependent, relationship_kinds: ["child", "adopted_child", "foster_child", "stepchild", "ward"], age_threshold: 26, age_comparison: :<, disability_qualifier: nil
        ),
        BenefitMarkets::PricingModels::MemberRelationship.new(
          relationship_name: :dependent, relationship_kinds: ["child", "adopted_child", "foster_child", "stepchild", "ward"], age_threshold: 26, age_comparison: :>=, disability_qualifier: nil
        )
      ]
    )

    contribution_model = BenefitMarkets::ContributionModels::ContributionModel.new(
      title: "#{state} Shop Simple List Bill Contribution Model",
      key: nil,
      sponsor_contribution_kind: "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
      contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator",
      many_simultaneous_contribution_units: true,
      product_multiplicities: [:single],
      contribution_units: [
        BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
          name: "employee", display_name: "Employee", order: 0, _type: "BenefitMarkets::ContributionModels::FixedPercentContributionUnit", default_contribution_factor: 0.5, minimum_contribution_factor: 0.0,
          member_relationship_maps: [
            BenefitMarkets::ContributionModels::MemberRelationshipMap.new(
              relationship_name: :employee, operator: :==, count: 1
            )
          ]
        ),
        BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
          name: "spouse", display_name: "Spouse", order: 1, _type: "BenefitMarkets::ContributionModels::FixedPercentContributionUnit", default_contribution_factor: 0.0, minimum_contribution_factor: 0.0,
          member_relationship_maps: [
            BenefitMarkets::ContributionModels::MemberRelationshipMap.new(
              relationship_name: :spouse, operator: :>=, count: 1
            )
          ]
        ),
        BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
          name: "domestic_partner", display_name: "Domestic Partner", order: 2, _type: "BenefitMarkets::ContributionModels::FixedPercentContributionUnit", default_contribution_factor: 0.0, minimum_contribution_factor: 0.0,
          member_relationship_maps: [
            BenefitMarkets::ContributionModels::MemberRelationshipMap.new(
              relationship_name: :domestic_partner, operator: :>=, count: 1
            )
          ]
        ),
        BenefitMarkets::ContributionModels::FixedPercentContributionUnit.new(
          name: "dependent", display_name: "Child Under 26", order: 3, _type: "BenefitMarkets::ContributionModels::FixedPercentContributionUnit", default_contribution_factor: 0.0, minimum_contribution_factor: 0.0,
          member_relationship_maps: [
            BenefitMarkets::ContributionModels::MemberRelationshipMap.new(
              relationship_name: :dependent, operator: :>=, count: 1
            )
          ]
        )
      ],
      member_relationships: [
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: :employee, relationship_kinds: ["self"], age_threshold: nil, age_comparison: nil, disability_qualifier: nil
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: :spouse, relationship_kinds: ["spouse"], age_threshold: nil, age_comparison: nil, disability_qualifier: nil
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: :domestic_partner, relationship_kinds: ["life_partner", "domestic_partner"], age_threshold: nil, age_comparison: nil, disability_qualifier: nil
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: :dependent, relationship_kinds: ["child", "adopted_child", "foster_child", "stepchild", "ward"], age_threshold: 26, age_comparison: :<, disability_qualifier: nil
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: :dependent, relationship_kinds: ["ward", "child", "adopted_child", "foster_child", "stepchild"], age_threshold: 26, age_comparison: :>=, disability_qualifier: nil
        )
      ]
    )

    # Build this for fehb market as well
    [shop_market].each do |market|
      years.each do |year|
        start_date = Date.new(year, 1, 1)
        end_date = start_date.end_of_year
        products = BenefitMarkets::Products::Product.where(:"application_period.min" => start_date, :"application_period.max" => end_date, benefit_market_kind: market.kind)
        catalog = BenefitMarkets::BenefitMarketCatalog.create(
          application_interval_kind: :monthly,
          application_period: {"min"=> start_date, "max"=> end_date},
          probation_period_kinds: [:first_of_month_before_15th, :date_of_hire, :first_of_month, :first_of_month_following, :first_of_month_after_30_days, :first_of_month_after_60_days],
          title: "#{state} Health Link SHOP Benefit Catalog",
          benefit_market_id: market.id,
        )

        product_packages = [
          BenefitMarkets::Products::ProductPackage.new(
            application_period: {"min"=> start_date, "max"=> end_date}, benefit_kind: :aca_shop, product_kind: :health, package_kind: :single_issuer, title: "Single Issuer", pricing_model: pricing_model, contribution_model: contribution_model,
            products: products.where(:kind => :health, :"product_package_kinds" => :single_issuer)
          ),
          BenefitMarkets::Products::ProductPackage.new(
            application_period: {"min"=> start_date, "max"=> end_date}, benefit_kind: :aca_shop, product_kind: :health, package_kind: :metal_level, title: "Metal Level", pricing_model: pricing_model, contribution_model: contribution_model,
            products: products.where(:kind => :health, :"product_package_kinds" => :metal_level)
          ),
          BenefitMarkets::Products::ProductPackage.new(
            application_period: {"min"=> start_date, "max"=> end_date}, benefit_kind: :aca_shop, product_kind: :health, package_kind: :single_product, title: "Single Product", pricing_model: pricing_model, contribution_model: contribution_model,
            products: products.where(:kind => :health, :"product_package_kinds" => :single_product)
          ),
          BenefitMarkets::Products::ProductPackage.new(
            application_period: {"min"=> start_date, "max"=> end_date}, benefit_kind: :aca_shop, product_kind: :dental, package_kind: :single_issuer, title: "Single Issuer", pricing_model: pricing_model, contribution_model: contribution_model,
            products: products.where(:kind => :dental, :"product_package_kinds" => :single_issuer)
          ),
          BenefitMarkets::Products::ProductPackage.new(
            application_period: {"min"=> start_date, "max"=> end_date}, benefit_kind: :aca_shop, product_kind: :dental, package_kind: :multi_product, title: "Multi Product", pricing_model: pricing_model, contribution_model: contribution_model,
            products: products.where(:kind => :dental, :"product_package_kinds" => :multi_product)
          )
        ]

        catalog.product_packages = product_packages
        catalog.save!
      end
    end

    puts ":::: Created markets, pricing models, contribution units ::::"
  end
end
