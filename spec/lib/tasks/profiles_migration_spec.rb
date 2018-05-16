require 'rails_helper'
require 'spec_helper'
require 'rake'

describe "profiles migration" do

  before :all do
    Rake.application.rake_require "tasks/migrations/profiles_migration"
    Rake::Task.define_task(:environment)
  end

  before :each do
    Rake::Task["profiles_migration"].reenable
    site.owner_organization = owner_organization
    site.save!
  end

  let(:site) {BenefitSponsors::Site.new(site_key: :dc)}
  let(:owner_organization) {BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: "DC", fein: 123456789, site: site, profiles: [profile])}
  let(:address) {BenefitSponsors::Locations::Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County")}
  let(:phone) {BenefitSponsors::Locations::Phone.new(kind: "main", area_code: "202", number: "555-9999")}
  let(:office_location) {BenefitSponsors::Locations::OfficeLocation.new(is_primary: true, address: address, phone: phone)}
  let(:office_locations) {[office_location]}
  let(:profile) {BenefitSponsors::Organizations::HbxProfile.new(office_locations: office_locations)}

  let(:organization) {FactoryGirl.create(:organization, legal_name: "bk_one", dba: "bk_corp", home_page: "http://www.example.com")}
  let!(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization)}
  let!(:employer_profile) {FactoryGirl.create(:employer_profile)}

  after(:all) do
    dir_path = "#{Rails.root}/hbx_report/"
    Dir.foreach(dir_path) do |file|
      File.delete File.join(dir_path, file) if File.file?(File.join(dir_path, file))
    end
    Dir.delete(dir_path)
  end

  it 'should migrate the data related to employer profiles' do
    ENV['site_key'] = "dc"
    ENV['profile_type'] = "employer_profile"
    Rake::Task["profiles_migration"].invoke
    expect(BenefitSponsors::Organizations::Organization.employer_profiles.count).to eq Organization.all_employer_profiles.count
  end

  it 'should migrate the data related to broker agency profiles' do
    ENV['site_key'] = "dc"
    ENV['profile_type'] = "broker_agency_profile"
    Rake::Task["profiles_migration"].invoke
    expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.count).to eq Organization.has_broker_agency_profile.count
  end
end