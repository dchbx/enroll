require 'rails_helper'

describe "CcaCarrierProfilesMigration" do

  before :all do
    DatabaseCleaner.clean

    Dir[Rails.root.join('db', 'migrate', '*_cca_carrier_profiles_migration.rb')].each do |f|
      @path = f
      require f
    end
  end

  describe ".up" do

    before :all do
      FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, site_key: :cca)
      organization = FactoryGirl.create(:organization, legal_name: "bk_one", dba: "bk_corp", home_page: "http://www.example.com")
      FactoryGirl.create(:broker_agency_profile, organization: organization)


      create_list(:carrier_profile, 9)

      @employer_profile = FactoryGirl.create(:employer_profile)
      FactoryGirl.create(:inbox, :with_message, recipient: @employer_profile)
      FactoryGirl.create(:employer_staff_role, employer_profile_id: @employer_profile.id, benefit_sponsor_employer_profile_id: "123456")
      FactoryGirl.create(:employee_role, employer_profile: @employer_profile)

      @migrated_organizations = BenefitSponsors::Organizations::Organization.issuer_profiles
      @old_organizations = Organization.exists(carrier_profile: true)


      @migrations_paths = Rails.root.join("db/migrate")
      @test_version = @path.split("/").last.split("_").first
    end

    it "should match total migrated organizations with carrier profiles" do
      silence_stream(STDOUT) do
        Mongoid::Migrator.run(:up, @migrations_paths, @test_version.to_i)
      end

      expect(@migrated_organizations.count).to eq 9
    end

    it "should not migrate organizations with broker agency profile" do
      expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.count).to eq 0
    end

    it "should match attribute" do
      expect(@migrated_organizations.first.issuer_profile.issuer_hios_ids.first).to eq @old_organizations.first.carrier_profile.issuer_hios_ids.first
    end

    it "should match office locations" do
      expect(@migrated_organizations.first.issuer_profile.office_locations.count).to eq @old_organizations.first.office_locations.count
    end

    it "should match address" do
      expect(@migrated_organizations.first.issuer_profile.office_locations.first.address.zip).to eq @old_organizations.first.office_locations.first.address.zip
    end

    it "should match phone" do
      expect(@migrated_organizations.first.issuer_profile.office_locations.first.phone.full_phone_number).to eq @old_organizations.first.office_locations.first.phone.full_phone_number
    end
  end
  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report//carrier_profile_migration_*"])
  end
end

