glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "data_migrations", "data_migration_*.yaml")

Mongoid::Migration.say_with_time("Load Data Migration Status") do
  Dir.glob(glob_pattern).each do |f_name|
    loaded_class = ::DataMigration
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
