namespace :shop do
  desc "Load site data"
  task :site_seed => :environment do

    puts ":::: Creating Site ::::" unless Rails.env.test?

    site_key = Settings.site.key
    state = site_key.upcase.to_s

    site = BenefitSponsors::Site.new(
      site_key: site_key,
      long_name: "#{state} Health Exchange Benefit",
      short_name: "#{state} Health Link",
      byline: "#{state}'s Online Health Insurance Marketplace",
      domain_name: "https://enroll.#{site_key.to_s}healthlink.com",
    )

    ol = BenefitSponsors::Locations::OfficeLocation.new(
      is_primary: true,
      address: BenefitSponsors::Locations::Address.new(
        kind: "work", address_1: "1225 I St, NW", address_2: "", address_3: "", city: "Washington", county: "", state: state, location_state_code: nil, full_text: nil, zip: "20002", country_name: ""
      ),
      phone: BenefitSponsors::Locations::Phone.new(
        kind: "main", country_code: "", area_code: "855", number: "5325465", extension: "", primary: nil, full_phone_number: "8555325465"
      )
    )

    profile = BenefitSponsors::Organizations::HbxProfile.new(
      is_benefit_sponsorship_eligible: true,
      contact_method: :paper_and_electronic,
      _type: "BenefitSponsors::Organizations::HbxProfile",
      cms_id: "#{state}0",
      us_state_abbreviation: "#{state}",
      office_locations: [ol]
    )

    owner_organization = BenefitSponsors::Organizations::ExemptOrganization.new(
      legal_name: "#{state} Health Link",
      dba: state,
      entity_kind: nil,
      fein: "123123456",
      site_id: site.id,
      profiles: [ profile ]
    )

    site.owner_organization = owner_organization
    site.save!

    puts ":::: Created Site ::::" unless Rails.env.test?
  end
end

RSpec.describe "site seed", dbclean: :after_each do
  require 'rake'

  before :each do
    Rake::Task.define_task(:environment)
    Rake::Task['shop:site_seed'].invoke
  end

  it "should create site" do
    expect(BenefitSponsors::Site.all.size).to eq 1
  end
end

