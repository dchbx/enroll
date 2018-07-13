qle_pattern = File.join(File.dirname(__FILE__), "fixtures", "qles", "qle_*.yaml")

::Mongoid::Migration.say_with_time("Load MA QLEs") do
  Dir.glob(qle_pattern).each do |f_name|
    loaded_class_1 = ::QualifyingLifeEventKind
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
