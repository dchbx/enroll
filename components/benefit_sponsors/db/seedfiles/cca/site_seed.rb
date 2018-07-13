site_glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "site_*.yaml")
owner_org_glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "owner_organization_*.yaml")

Mongoid::Migration.say_with_time("Load MA Site") do
  owner_org = nil
  Dir.glob(owner_org_glob_pattern).each do |f_name|
    loaded_class = ::BenefitSponsors::Organizations::ExemptOrganization
    yaml_str = File.read(f_name)
    owner_org = YAML.load(yaml_str)
  end

  site = nil
  Dir.glob(site_glob_pattern).each do |f_name|
    loaded_class = ::BenefitSponsors::Site
    yaml_str = File.read(f_name)
    data = YAML.load(yaml_str)
    data.new_record = true
    owner_org.site = data
    data.owner_organization = owner_org
    data.save!
    owner_org.new_record = true
    owner_org.save!
  end
end
