cz_pattern = File.join(File.dirname(__FILE__), "fixtures", "factors", "actuarial_factor_*.yaml")

Mongoid::Migration.say_with_time("Load MA Actuarial Factors") do
  Dir.glob(cz_pattern).each do |f_name|
    loaded_class_1 = ::BenefitMarkets::Products::ActuarialFactors::CompositeRatingTierActuarialFactor
    loaded_class_2 = ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor
    loaded_class_3 = ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor
    loaded_class_4 = ::BenefitMarkets::Products::ActuarialFactors::SicActuarialFactor
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
