def load_cca_locations_county_zips_seed
  cz_pattern = File.join(File.dirname(__FILE__), "fixtures", "locations", "county_zips", "county_zips_*.yaml")

  Dir.glob(cz_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::Locations::CountyZip
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end

def load_ma_locations_rating_areas_seed
  ra_pattern = File.join(File.dirname(__FILE__), "fixtures", "locations", "rating_areas", "rating_area_*.yaml")
  Dir.glob(ra_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::Locations::RatingArea
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end

def load_ma_locations_service_areas_seed
  sa_pattern = File.join(File.dirname(__FILE__), "fixtures", "locations", "service_areas", "service_area_*.yaml")
  Dir.glob(sa_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::Locations::ServiceArea
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end