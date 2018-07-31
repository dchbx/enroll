require 'rails_helper'

describe "CcaEmployerProfilesMigration" do

  before :all do
    DatabaseCleaner.clean

    Dir[Rails.root.join('db', 'migrate', '*_cca_employer_profiles_migration.rb')].each do |f|
      @path = f
      require f
    end
  end

  describe ".up" do

    let!(:site) {FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, site_key: :cca)}
    let!(:benefit_market) {FactoryGirl.create(:benefit_markets_benefit_market)}
    let!(:site_assign) {site.benefit_markets << benefit_market}
    let!(:saved) {site.save!}

    before :all do
      organization = FactoryGirl.create(:organization, legal_name: "bk_one", dba: "bk_corp", home_page: "http://www.example.com")
      FactoryGirl.create(:broker_agency_profile, organization: organization)

      organization1 = FactoryGirl.create(:organization, legal_name: "Delta Dental")
      FactoryGirl.create(:carrier_profile, organization: organization1)

      employer_profile = FactoryGirl.create(:employer_profile)
      document1 = FactoryGirl.build(:document)
      document2 = FactoryGirl.build(:document)
      employer_profile.organization.documents << document1
      employer_profile.documents << document2
      employer_profile.documents.first.update_attributes(title: "MonthlyInvoiceAvailableNotice", creator: "hbx_staff", subject: "notice", description: nil, publisher: "dchl", type: "text", format: "application/pdf", identifier: "urn:openhbx:terms:v1:file_storage:s10:buckt:dchbx-enroll-notices-dev#92a6d67d", source: "enroll_system", language: "en", _type: "Document")

      # employer_profile.organization.home_page = nil
      inbox = FactoryGirl.create(:inbox, :with_message, recipient: employer_profile)
      inbox.messages.first.update_attributes(body: "<br>Your invoice is now available in your employer profile under the Billing tab. For more information, please download your <a href=/document/authorized_download/EmployerProfile/#{employer_profile.id}/documents/#{document1.id}?content_type=application/pdf&filename=MonthlyInvoiceAvailableNotice.pdf&disposition=inline target='_blank'>MonthlyInvoiceAvailableNotice</a>")
      FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id, benefit_sponsor_employer_profile_id: "123456")
      FactoryGirl.create(:employee_role, employer_profile: employer_profile)
      FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)

      @migrated_organizations = BenefitSponsors::Organizations::Organization.employer_profiles
      @old_organizations = Organization.all_employer_profiles

      @migrations_paths = Rails.root.join("db/migrate")
      @test_version = @path.split("/").last.split("_").first
    end

    #TODO modify it after employer profile script is updated according to benefit sponsorship
    it "should match total migrated organizations" do
      silence_stream(STDOUT) do
        Mongoid::Migrator.run(:up, @migrations_paths, @test_version.to_i)
      end

      expect(@migrated_organizations.count).to eq 1
    end

    it "should not migrate organizations with broker agency profile" do
      expect(BenefitSponsors::Organizations::Organization.broker_agency_profiles.count).to eq 0
    end

    it "should match messages" do
      migrated_profile = @migrated_organizations.first.employer_profile
      expect(migrated_profile.inbox.messages.count).to eq @old_organizations.first.employer_profile.inbox.messages.count
    end

    it "should match documents" do
      migrated_profile = @migrated_organizations.first.employer_profile
      expect(migrated_profile.documents.count).to eq @old_organizations.first.employer_profile.documents.count + @old_organizations.first.documents.count
    end

    it "should match office locations" do
      migrated_profile = @migrated_organizations.first.employer_profile
      expect(migrated_profile.office_locations.count).to eq 2
    end

    it "should match all migrated attributes for address" do
      migrated_profile = @migrated_organizations.first.employer_profile
      migrated_address = migrated_profile.office_locations.first.address
      old_address = @old_organizations.first.office_locations.first.address
      expect(migrated_address).to have_attributes(created_at: old_address.created_at,
                                                  updated_at: old_address.updated_at, kind: old_address.kind, address_1: old_address.address_1,
                                                  address_2: old_address.address_2, address_3: old_address.address_3, city: old_address.city,
                                                  county: (old_address.county ? old_address.county : ''), state: old_address.state, location_state_code: old_address.location_state_code,
                                                  full_text: old_address.full_text, zip: old_address.zip, country_name: old_address.country_name)
    end

    it "should match all migrated attributes for phone" do
      migrated_profile = @migrated_organizations.first.employer_profile
      migrated_phone = migrated_profile.office_locations.first.phone
      old_phone = @old_organizations.first.office_locations.first.phone
      expect(migrated_phone).to have_attributes(created_at: old_phone.created_at, updated_at: old_phone.updated_at, kind: old_phone.kind,
                                                country_code: old_phone.country_code, area_code: old_phone.area_code, number: old_phone.number,
                                                extension: old_phone.extension, primary: old_phone.primary, full_phone_number: old_phone.full_phone_number)
    end

    it "should be same person with old profile id and migrated profile id" do
      migrated_profile = @migrated_organizations.first.employer_profile
      old_profile = @old_organizations.first.employer_profile
      person_with_old_profile_id = Person.where(:employer_staff_roles => {'$elemMatch' => {benefit_sponsor_employer_profile_id: migrated_profile.id}}).first
      person_with_migrated_profile_id = Person.where(:employer_staff_roles => {'$elemMatch' => {employer_profile_id: old_profile.id}}).first
      expect(person_with_old_profile_id).to eq person_with_migrated_profile_id
    end

    it "should match all migrated attributes for employer profile" do
      migrated_profile = @migrated_organizations.first.employer_profile
      old_profile = @old_organizations.first.employer_profile
      expect(migrated_profile).to have_attributes( created_at: old_profile.created_at,
                                                  updated_at: old_profile.updated_at, aasm_state: old_profile.aasm_state)
    end

    it "should match all migrated attributes for employer profile" do
      migrated_profile = @migrated_organizations.first.employer_profile
      old_profile = @old_organizations.first.employer_profile
      if old_profile.contact_method == "Only Electronic communications"
        expect(migrated_profile.contact_method).to eq :electronic_only
      elsif old_profile.contact_method == "Paper and Electronic communications"
        expect(migrated_profile.contact_method).to eq :paper_and_electronic
      elsif old_profile.contact_method == "Only Paper communication"
        expect(migrated_profile.contact_method).to eq :paper_only
      end
    end


    it "should match all migrated attributes for organization" do
      old_organization = @old_organizations.first
      expect(@migrated_organizations.first).to have_attributes(entity_kind: @old_organizations.first.employer_profile.entity_kind.to_sym, created_at: old_organization.created_at,
                                                               hbx_id: old_organization.hbx_id, home_page: old_organization.home_page, legal_name: old_organization.legal_name,
                                                               dba: old_organization.dba, fein: old_organization.fein)
    end

    it "should have benefit sponsorship created" do
      expect(@migrated_organizations.first.benefit_sponsorships.count).to eq 1
    end

    it "should match all migrated attributes for census employee" do
      migrated_profile = @migrated_organizations.first.employer_profile
      old_profile = @old_organizations.first.employer_profile
      ce = CensusEmployee.where(employer_profile_id: old_profile.id).first
      nce = CensusEmployee.where(benefit_sponsors_employer_profile_id: migrated_profile.id).first
      expect(ce).to eq(nce)
      expect(nce.benefit_sponsorship_id).to eq(@migrated_organizations.first.benefit_sponsorships.first.id)
    end
  end
  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report//employer_profiles_migration_*"])
  end
end
