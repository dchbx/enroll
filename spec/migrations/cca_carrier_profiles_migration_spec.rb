require 'rails_helper'

describe "CcaCarrierProfilesMigration" do

  if Settings.site.key.to_s == "cca"

    before :all do
      Dir[Rails.root.join('db', 'migrate', '*_cca_carrier_profiles_migration.rb')].each do |f|
        @path = f
        require f
      end
    end

    describe ".up", dbclean: :after_each do

      before :each do
        FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, site_key: :cca)
        organization = FactoryBot.create(:organization, legal_name: "bk_one", dba: "bk_corp", home_page: "http://www.example.com")
        FactoryBot.create(:broker_agency_profile, organization: organization)


        create_list(:carrier_profile, 9)

        @employer_profile = FactoryBot.create(:employer_profile)
        FactoryBot.create(:inbox, :with_message, recipient: @employer_profile)
        FactoryBot.create(:employer_staff_role, employer_profile_id: @employer_profile.id)
        FactoryBot.create(:employee_role, employer_profile: @employer_profile)

        @migrated_organizations = BenefitSponsors::Organizations::Organization.issuer_profiles
        @old_organizations = Organization.exists(carrier_profile: true)


        @migrations_paths = Rails.root.join("db/migrate")
        @test_version = @path.split("/").last.split("_").first
        Mongoid::Migrator.run(:up, @migrations_paths, @test_version.to_i)
      end

      it "should match total migrated organizations with carrier profiles" do
        expect(@migrated_organizations.count).to eq 9
      end

      it "should not migrate organizations with broker agency profile" do
        expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.count).to eq 0
      end

    it "should match attribute" do
      migrated_organization = @migrated_organizations.first
      old_organization = @old_organizations.where(hbx_id: migrated_organization.hbx_id).first
      expect(migrated_organization.issuer_profile.issuer_hios_ids.first).to eq old_organization.carrier_profile.issuer_hios_ids.first
    end

      it "should match office locations" do
        expect(@migrated_organizations.first.issuer_profile.office_locations.count).to eq @old_organizations.first.office_locations.count
      end

      it "should match address" do
        expect(@migrated_organizations.first.issuer_profile.office_locations.first.address.zip).to eq @old_organizations.first.office_locations.first.address.zip
      end

      it "should match phone" do
        hbx_id = @old_organizations.first.hbx_id
        expect(@migrated_organizations.where(hbx_id: hbx_id).first.issuer_profile.office_locations.first.phone.full_phone_number).to eq @old_organizations.where(hbx_id: hbx_id).first.office_locations.first.phone.full_phone_number
        expect(@old_organizations.map(&:office_locations).flatten.map(&:phone).map(&:full_phone_number).include?(@migrated_organizations.first.issuer_profile.office_locations.first.phone.full_phone_number)).to eq true
      end
    end
    after(:each) do
      FileUtils.rm_rf(Dir["#{Rails.root}/hbx_report/carrier_profile_migration_*"])
    end
  end
end

