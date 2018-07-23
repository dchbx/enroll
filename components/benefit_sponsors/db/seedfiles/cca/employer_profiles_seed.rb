glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "employer_profile_*.yaml")

Mongoid::Migration.say_with_time("Load MA employer Profiles") do
  Dir.glob(glob_pattern).each do |f_name|
    loaded_class = ::BenefitSponsors::Organizations::GeneralOrganization
    loaded_class_2 = ::BenefitSponsors::Organizations::AcaShopCcaEmployerProfile
    site = BenefitSponsors::Site.all.first
    yaml_str = File.read(f_name)
    hbx_id = yaml_str.split("\n")[10].split("hbx_id: ").last
    org = BenefitSponsors::Organizations::Organization.where(hbx_id: hbx_id)
    org.destroy if org.present?
    organization = YAML.load(yaml_str)
    organization.new_record = true
    organization.site = site
    benefit_sponsorship = organization.employer_profile.add_benefit_sponsorship
    benefit_sponsorship.save!
    organization.save!
  end
end
