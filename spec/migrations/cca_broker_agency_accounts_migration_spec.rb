require 'rails_helper'

describe "CcaBrokerAgencyAccountsMigration" do

  before :all do
    DatabaseCleaner.clean

    Dir[Rails.root.join('db', 'migrate', '*_cca_broker_agency_accounts_migration.rb')].each do |f|
      @broker_agency_accounts_migration_path = f
      require f
    end

    Dir[Rails.root.join('db', 'migrate', '*_cca_broker_agency_profiles_migration.rb')].each do |f|
      @broker_agency_profiles_migration_path = f
      require f
    end

    Dir[Rails.root.join('db', 'migrate', '*_cca_employer_profiles_migration.rb')].each do |f|
      @employer_profiles_migration_path = f
      require f
    end
  end

  describe ".up" do
    let!(:site) {FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, site_key: :cca)}
    let!(:benefit_market) {FactoryGirl.create(:benefit_markets_benefit_market)}
    let!(:site_assign) {site.benefit_markets << benefit_market}
    let!(:saved) {site.save!}


    before :all do

      organization1 = FactoryGirl.create(:broker)
      FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: organization1.broker_agency_profile, benefit_sponsors_broker_agency_profile_id: "123456")
      broker_role1 = FactoryGirl.create(:broker_role, broker_agency_profile_id: organization1.broker_agency_profile.id)

      organization2 = FactoryGirl.create(:broker)
      FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: organization2.broker_agency_profile, benefit_sponsors_broker_agency_profile_id: "123457")
      broker_role2 = FactoryGirl.create(:broker_role, broker_agency_profile_id: organization2.broker_agency_profile.id)

      organization3 = FactoryGirl.create(:broker)
      FactoryGirl.create(:broker_agency_staff_role, broker_agency_profile: organization3.broker_agency_profile, benefit_sponsors_broker_agency_profile_id: "123458")
      broker_role3 =FactoryGirl.create(:broker_role, broker_agency_profile_id: organization3.broker_agency_profile.id)

      employer_profile = FactoryGirl.create(:employer_profile, created_at: TimeKeeper.date_of_record - 2.year, registered_on: TimeKeeper.date_of_record - 2.year)
      employer_profile.organization.created_at = TimeKeeper.date_of_record - 2.year
      FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id, benefit_sponsor_employer_profile_id: "12456")

      employer_profile2 = FactoryGirl.create(:employer_profile, created_at: TimeKeeper.date_of_record - 2.year, registered_on: TimeKeeper.date_of_record - 2.year)
      employer_profile2.organization.created_at = TimeKeeper.date_of_record - 2.year
      FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile2.id, benefit_sponsor_employer_profile_id: "12457")


      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile: organization1.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record, end_on: nil, writing_agent: broker_role1, is_active: false)
      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile: organization1.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record + 1.day, end_on: TimeKeeper.date_of_record + 1.day, writing_agent: broker_role1, is_active: true)
      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile: organization1.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record - 1.day, end_on: TimeKeeper.date_of_record - 1.day, writing_agent: broker_role1, is_active: false)
      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile: organization1.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record - 1.year + 1.day, end_on: TimeKeeper.date_of_record - 6.months, writing_agent: broker_role2, is_active: false)
      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile: organization1.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record - 2.year + 1.day, end_on: TimeKeeper.date_of_record - 1.year - 6.months, writing_agent: broker_role3, is_active: false)

      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile2, broker_agency_profile: organization2.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record + 1.day, end_on: nil, writing_agent: broker_role1, is_active: true)
      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile2, broker_agency_profile: organization2.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record - 1.year + 1.day, end_on: TimeKeeper.date_of_record - 6.months, writing_agent: broker_role2, is_active: false)
      FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile2, broker_agency_profile: organization2.broker_agency_profile,
                         start_on: TimeKeeper.date_of_record - 2.year + 1.day, end_on: TimeKeeper.date_of_record - 1.year - 6.months, writing_agent: broker_role3, is_active: false)

      @orgs_with_emp_profile = BenefitSponsors::Organizations::Organization.employer_profiles
      @old_orgs_with_emp_profile = Organization.all_employer_profiles

      @orgs_with_bk_profile = BenefitSponsors::Organizations::Organization.broker_agency_profiles
      @old_orgs_with_bk_profile = Organization.has_broker_agency_profile

      @migrations_paths = Rails.root.join("db/migrate")
      @emp_migration_version = @employer_profiles_migration_path.split("/").last.split("_").first
      @bk_migration_version = @broker_agency_profiles_migration_path.split("/").last.split("_").first
      @baa_migration_version = @broker_agency_accounts_migration_path.split("/").last.split("_").first
    end


    it "should start and complete profiles migrations" do
      silence_stream(STDOUT) do
        Mongoid::Migrator.run(:up, @migrations_paths, @emp_migration_version.to_i)
        Mongoid::Migrator.run(:up, @migrations_paths, @bk_migration_version.to_i)
      end

      @orgs_with_emp_profile.each do |migrated_organization|

        benefit_sponsorship2 = migrated_organization.employer_profile.add_benefit_sponsorship
        old_org = Organization.all_employer_profiles.where(hbx_id: migrated_organization.hbx_id)
        benefit_sponsorship2.effective_begin_on = TimeKeeper.date_of_record - 2.year
        benefit_sponsorship2.effective_end_on = TimeKeeper.date_of_record - 1.year
        benefit_sponsorship2.source_kind = old_org.first.employer_profile.profile_source.to_sym
        benefit_sponsorship2.save!

        benefit_sponsorship = migrated_organization.employer_profile.add_benefit_sponsorship
        old_org = Organization.all_employer_profiles.where(hbx_id: migrated_organization.hbx_id)
        benefit_sponsorship.effective_begin_on = TimeKeeper.date_of_record - 1.year
        benefit_sponsorship.effective_end_on = TimeKeeper.date_of_record - 1.day
        benefit_sponsorship.source_kind = old_org.first.employer_profile.profile_source.to_sym
        benefit_sponsorship.save!
      end

    end

    describe "after profiles migration" do

      it "should start and complete accounts migrations" do
        silence_stream(STDOUT) do
          Mongoid::Migrator.run(:up, @migrations_paths, @baa_migration_version.to_i)
        end
      end

      it "should have benefit sponsorships" do
        bs = @orgs_with_emp_profile.first.benefit_sponsorships.unscoped
        expect(bs.count).to eq 3
      end

      it "should match new_org broker agency account to old_org" do
        @orgs_with_emp_profile.each do |org_with_emp_profile|
          hbx_id = org_with_emp_profile.hbx_id
          old_org_with_emp_profile = @old_orgs_with_emp_profile.where(hbx_id: hbx_id).first
          bss = org_with_emp_profile.benefit_sponsorships.unscoped
          old_baa = old_org_with_emp_profile.employer_profile.broker_agency_accounts.unscoped

          arrayed = bss.map {|benefit_sponsorship| benefit_sponsorship.broker_agency_accounts.unscoped.count}
          total_migrated_bk_agency_accs = arrayed.reduce(0, :+)

          expect(total_migrated_bk_agency_accs).to eq old_baa.count
        end
      end
    end
  end
  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report//*_migration_status_*"])
  end
end