cz_pattern = File.join(File.dirname(__FILE__), "fixtures", "locations", "county_zips", "county_zips_*.yaml")
ra_pattern = File.join(File.dirname(__FILE__), "fixtures", "locations", "rating_areas", "rating_area_*.yaml")
sa_pattern = File.join(File.dirname(__FILE__), "fixtures", "locations", "service_areas", "service_area_*.yaml")

Mongoid::Migration.say_with_time("Load MA County Zips") do
  Dir.glob(cz_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::Locations::CountyZip
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end

Mongoid::Migration.say_with_time("Load MA Rating Areas") do
  Dir.glob(ra_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::Locations::RatingArea
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end

Mongoid::Migration.say_with_time("Load MA Service Areas") do
  Dir.glob(sa_pattern).each do |f_name|
    loaded_class = ::BenefitMarkets::Locations::ServiceArea
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
