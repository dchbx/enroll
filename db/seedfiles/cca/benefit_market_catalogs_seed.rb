def load_cca_benefit_market_catalogs_seed
    cz_pattern = File.join(File.dirname(__FILE__), "fixtures", "benefit_market_catalog_*.yaml")
  
    Dir.glob(cz_pattern).each do |f_name|
      loaded_class_1 = ::BenefitMarkets::BenefitMarketCatalog
      loaded_class_2 = ::BenefitMarkets::PricingModels::PricingModel
      loaded_class_3 = ::BenefitMarkets::PricingModels::TieredPricingUnit
      loaded_class_4 = ::BenefitMarkets::PricingModels::RelationshipPricingUnit
      loaded_class_5 = ::BenefitMarkets::ContributionModels::ContributionModel
      loaded_class_6 = ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit
      yaml_str = File.read(f_name)
      data = YAML.load(yaml_str)
      data.new_record = true
      data.save!
    end
  end