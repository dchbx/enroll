glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "issuer_profile_*.yaml")

Mongoid::Migration.say_with_time("Load MA Issuer Profiles") do
  Dir.glob(glob_pattern).each do |f_name|
    loaded_class = ::BenefitSponsors::Organizations::ExemptOrganization
    loaded_class_2 = ::BenefitSponsors::Organizations::IssuerProfile
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    data.save!
  end
end
