pm_pattern = File.join(File.dirname(__FILE__), "fixtures", "pricing_model_*.yaml")
cm_pattern = File.join(File.dirname(__FILE__), "fixtures", "contribution_model_*.yaml")

Mongoid::Migration.say_with_time("Load MA Pricing Models") do
  Dir.glob(pm_pattern).each do |f_name|
    loaded_class_1 = ::BenefitMarkets::PricingModels::PricingModel
    loaded_class_2 = ::BenefitMarkets::PricingModels::TieredPricingUnit
    loaded_class_3 = ::BenefitMarkets::PricingModels::RelationshipPricingUnit
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end

Mongoid::Migration.say_with_time("Load MA Contribution Models") do
  Dir.glob(cm_pattern).each do |f_name|
    loaded_class_1 = ::BenefitMarkets::ContributionModels::ContributionModel
    loaded_class_2 = ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
