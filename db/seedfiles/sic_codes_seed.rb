cz_pattern = File.join(File.dirname(__FILE__), "fixtures", "sic_codes", "sic_code_*.yaml")

Mongoid::Migration.say_with_time("Load SIC Codes") do
  Dir.glob(cz_pattern).each do |f_name|
    loaded_class_1 = ::SicCode
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
