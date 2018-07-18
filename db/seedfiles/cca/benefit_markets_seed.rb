def load_cca_benefit_markets_seed
  glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "benefit_markets", "*.yaml")

  Dir.glob(glob_pattern).each do |f_name|
    force_loaded_config = ::BenefitMarkets::Configurations::AcaShopConfiguration
    loaded_class = ::BenefitMarkets::BenefitMarket
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!(validate: false)
  end
end