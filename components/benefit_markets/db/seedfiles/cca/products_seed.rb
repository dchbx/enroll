cz_pattern = File.join(File.dirname(__FILE__), "fixtures", "products", "product_*.yaml")

Mongoid::Migration.say_with_time("Load MA Products") do
  Dir.glob(cz_pattern).each do |f_name|
    loaded_class_1 = ::BenefitMarkets::Products::HealthProducts::HealthProduct
    loaded_class_2 = ::BenefitMarkets::Products::DentalProducts::DentalProduct
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
