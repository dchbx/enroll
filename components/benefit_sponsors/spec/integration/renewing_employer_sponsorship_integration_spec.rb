require "rails_helper"
require "fileutils"

RSpec.describe "an MA ACA Employer" do

  def reload_db_fixtures
    warn "USING DB DUMP AS FIXTURES - REPLACE WITH CORRECTED FACTORY HARNESS"
    db_name = Mongoid::Config.clients[:default][:database]
    db_location = File.expand_path(File.join(File.dirname(__FILE__), "..", "fixture_dbs", "dump"))
    tmp_dir = Dir.mktmpdir
    dest_dir = File.join(tmp_dir, "dump")
    db_dump_src_dir = File.join(dest_dir, "fixture_source")
    db_dump_dest_dir = File.join(dest_dir, db_name)
    FileUtils.mkdir(dest_dir)
    FileUtils.cp_r(db_location, tmp_dir)
    FileUtils.mv(db_dump_src_dir, db_dump_dest_dir)
    `cd #{tmp_dir} && mongorestore --drop --quiet`
    FileUtils.rm_r(tmp_dir)
  end

  def primary_address_attributes
    {
      address_1: "27 Reo Road",
      state: "MA",
      zip: "01754",
      county: "Middlesex",
      city: "Maynard",
      kind: "work"
    }
  end

  def create_employer_profile
    primary_office_location = ::BenefitSponsors::Locations::OfficeLocation.new({
      :address => ::BenefitSponsors::Locations::Address.new(primary_address_attributes),
      :phone => BenefitSponsors::Locations::Phone.new({:area_code => "555", :number => "5555555", :kind => "phone main"}),
      is_primary: true
    })
    employer_profile = ::BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new({
      :sic_code => "2035",
      :contact_method => :paper_and_electronic,
      :office_locations => [primary_office_location]
    })
    employer_organization = ::BenefitSponsors::Organizations::GeneralOrganization.create!({
      :legal_name => "Generic Employer",
      :fein => "123423444",
      :entity_kind => "c_corporation",
      :profiles => [employer_profile],
      :site => ::BenefitSponsors::Site.first
    })
    employer_organization.profiles.first
  end

  def create_census_employee(employer_profile, benefit_sponsorship)
    census_employee = ::CensusEmployee.new({
      :benefit_sponsors_employer_profile_id => employer_profile.id,
      :dob => Date.new(1970, 3, 4),
      :ssn => "111111115",
      :first_name => "Employee",
      :last_name => "One",
      :gender => "male",
      :hired_on => Date.new(2014, 6, 15),
      :benefit_sponsorship_id => benefit_sponsorship.id
    })
    census_employee.save!
  end

  def create_sole_source_benefit_package(benefit_application)
    BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
    BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    p_package = benefit_application.benefit_sponsor_catalog.product_packages.detect { |p_package| p_package.package_kind == :single_product }
    reference_product = p_package.products.first
    factory = BenefitSponsors::BenefitPackages::BenefitPackageFactory
    benefit_package_attributes = {
      title: "My Sole-Source Package",
      probation_period_kind: :date_of_hire,
      sponsored_benefits_attributes: [{
        kind: :health,
        product_package_kind: :single_product,
        reference_product: reference_product,
        sponsor_contribution_attributes: {
          contribution_levels_attributes: []
        }
      }]
    }
    benefit_package = factory.call(benefit_application, benefit_package_attributes)
    cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(
      benefit_application.benefit_sponsorship,
      benefit_application.effective_period.min
    )
    sb = benefit_package.sponsored_benefits.first
    sbc, _price, _cont = cost_estimator.calculate(
      sb,
      sb.reference_product,
      sb.product_package,
      build_new_pricing_determination: true
    )
    sbc.save!
  end

=begin
  # TODO: We need to add more specs here, but since our fixes to the way
  # service and rating areas are calculated and attached to
  # benefit_sponsorships and benefit_applications.
  describe "with a 2017 benefit sponsorship", dbclean: :after_all do

    before :all do
      reload_db_fixtures
      employer_profile = create_employer_profile
      benefit_sponsorship = employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save!
      @benefit_sponsorship = benefit_sponsorship
    end

    after :all do
      DatabaseCleaner.clean
    end

    it "should have a recorded rating area of R-MA003 from 2018" do
      rating_area = @benefit_sponsorship.rating_area
      expect(rating_area.exchange_provided_code).to eq("R-MA003")
      expect(rating_area.active_year).to eq(2018)
    end

    it "should be in 9 of service areas" do
      service_areas = @benefit_sponsorship.service_areas
      expect(service_areas.count).to eq(9)
    end
  end
=end

  describe "with an initial 2017 benefit application", dbclean: :after_all do
    before :all do
      reload_db_fixtures
      employer_profile = create_employer_profile
      benefit_sponsorship = employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save!
      benefit_application = ::BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(
        benefit_sponsorship,
        effective_period: (Date.new(2017,12,1)..Date.new(2018,11,30)),
        open_enrollment_period: (Date.new(2017,1,1)..Date.new(2017,11,15)),
        fte_count: 5,
        pte_count: 0,
        msp_count: 0
      )
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.recorded_service_areas, benefit_application.effective_period.begin)
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog.save!
      @benefit_application = benefit_application
    end

    after :all do
      DatabaseCleaner.clean
    end

    it "should have a recorded rating area of R-MA003 from 2017" do
      rating_area = @benefit_application.recorded_rating_area
      expect(rating_area.exchange_provided_code).to eq("R-MA003")
      expect(rating_area.active_year).to eq(2017)
    end

    it "should be in 9 recorded service areas, from 2017" do
      service_areas = @benefit_application.recorded_service_areas
      expect(service_areas.count).to eq(11)
      service_area_years = service_areas.map(&:active_year).uniq
      expect(service_area_years).to eq([2017])
    end

    describe "and the resulting benefit_sponsor_catalog" do
      before :each do 
        @benefit_sponsor_catalog = @benefit_application.benefit_sponsor_catalog
      end

      it "has the correct service areas" do
        service_area_ids = @benefit_application.recorded_service_area_ids.sort
        catalog_service_area_ids = @benefit_sponsor_catalog.service_area_ids.sort
        expect(service_area_ids).to eq(catalog_service_area_ids)
      end

      it "has the correct effective dates" do
        ba_effective_period = @benefit_application.effective_period
        catalog_effective_period = @benefit_sponsor_catalog.effective_period
        expect(ba_effective_period).to eq catalog_effective_period
      end

      describe "and it's product packages" do
        before :each do
          @product_packages = @benefit_sponsor_catalog.product_packages
        end

        it "has the correct benefit packages for 2017" do
          package_types = @product_packages.map(&:package_kind)
          expect(@product_packages.count).to eq(3)
          expect(package_types).to include(:metal_level)
          expect(package_types).to include(:single_issuer)
          expect(package_types).to include(:single_product)
        end

        it "does NOT contain ALL of the single source products" do
          single_source_package = @product_packages.detect { |p_package| p_package.package_kind == :single_product }
          benefit_market_catalog = @benefit_application.benefit_sponsorship.benefit_market.benefit_market_catalog_effective_on(@benefit_application.start_on)
          benefit_market_single_source_package = benefit_market_catalog.product_packages.detect { |p_package| p_package.package_kind == :single_product }
          expect(single_source_package.products.count).not_to eq(benefit_market_single_source_package.products.count)
        end

        it "does NOT contain any products from service areas it does not occupy" do
          product_service_area_ids = @product_packages.flat_map(&:products).map(&:service_area_id).uniq.sort
          service_area_ids = @benefit_application.recorded_service_area_ids.sort
          expect(service_area_ids).to include(*product_service_area_ids)
        end
      end
    end
  end

  describe "given:
              - a 2017 benefit sponsorship
              - and employee
              - an initial 2017 benefit application, with a sole source selection made", dbclean: :after_all do
    before :all do
      reload_db_fixtures
      employer_profile = create_employer_profile
      benefit_sponsorship = employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save!
      benefit_application = ::BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(
        benefit_sponsorship,
        effective_period: (Date.new(2017,12,1)..Date.new(2018,11,30)),
        open_enrollment_period: (Date.new(2017,1,1)..Date.new(2017,11,15)),
        fte_count: 5,
        pte_count: 0,
        msp_count: 0
      )
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.recorded_service_areas, benefit_application.effective_period.begin)
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog.save!
      @benefit_application = benefit_application
      create_census_employee(employer_profile, benefit_sponsorship)
      create_sole_source_benefit_package(benefit_application)
      @benefit_application.reload
    end

    after :all do
      DatabaseCleaner.clean
    end

    it "has a benefit_package" do
      expect(@benefit_application.benefit_packages).not_to be_empty
    end

    it "has a sole source health sponsored benefit" do
      sponsored_benefits = @benefit_application.benefit_packages.flat_map(&:sponsored_benefits)
      expect(sponsored_benefits).not_to be_empty
    end

    describe "with the sole source health sponsored benefit" do
      before :each do
        sponsored_benefits = @benefit_application.benefit_packages.flat_map(&:sponsored_benefits)
        @sponsored_benefit = sponsored_benefits.first
      end

      it "has a default sponsor contribution" do
        expect(@sponsored_benefit.sponsor_contribution).not_to eq(nil)
      end

      it "has a pricing determination" do
        expect(@sponsored_benefit.latest_pricing_determination).not_to be(nil)
      end

      describe "with the default contribution" do
        before :each do
          @sponsor_contribution = @sponsored_benefit.sponsor_contribution
        end

        it "has the correct number of contribution levels" do
          expect(@sponsor_contribution.contribution_levels.count).to eq(2)
        end
      end

      describe "with the resulting pricing determination" do
        before :each do
          @pricing_determination = @sponsored_benefit.latest_pricing_determination
        end

        it "has the correct number of tiers" do
          expect(@pricing_determination.pricing_determination_tiers.count).to eq(4)
        end
      end
    end
  end

  describe "given:
              - a 2017 benefit sponsorship
              - with NO employee
              - an initial 2017 benefit application, with a sole source selection made", dbclean: :after_all do
    before :all do
      reload_db_fixtures
      employer_profile = create_employer_profile
      benefit_sponsorship = employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save!
      benefit_application = ::BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(
        benefit_sponsorship,
        effective_period: (Date.new(2017,12,1)..Date.new(2018,11,30)),
        open_enrollment_period: (Date.new(2017,1,1)..Date.new(2017,11,15)),
        fte_count: 5,
        pte_count: 0,
        msp_count: 0
      )
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.recorded_service_areas, benefit_application.effective_period.begin)
      benefit_application.save!
      benefit_application.benefit_sponsor_catalog.save!
      @benefit_application = benefit_application
      create_sole_source_benefit_package(benefit_application)
      @benefit_application.reload
    end

    after :all do
      DatabaseCleaner.clean
    end

    it "has a benefit_package" do
      expect(@benefit_application.benefit_packages).not_to be_empty
    end

    it "has a sole source health sponsored benefit" do
      sponsored_benefits = @benefit_application.benefit_packages.flat_map(&:sponsored_benefits)
      expect(sponsored_benefits).not_to be_empty
    end

    describe "with the sole source health sponsored benefit" do
      before :each do
        sponsored_benefits = @benefit_application.benefit_packages.flat_map(&:sponsored_benefits)
        @sponsored_benefit = sponsored_benefits.first
      end

      it "has a default sponsor contribution" do
        expect(@sponsored_benefit.sponsor_contribution).not_to eq(nil)
      end

      it "has a pricing determination" do
        expect(@sponsored_benefit.latest_pricing_determination).not_to be(nil)
      end

      describe "with the default contribution" do
        before :each do
          @sponsor_contribution = @sponsored_benefit.sponsor_contribution
        end

        it "has the correct number of contribution levels" do
          expect(@sponsor_contribution.contribution_levels.count).to eq(2)
        end
      end

      describe "with the resulting pricing determination" do
        before :each do
          @pricing_determination = @sponsored_benefit.latest_pricing_determination
        end

        it "has the correct number of tiers" do
          expect(@pricing_determination.pricing_determination_tiers.count).to eq(4)
        end
      end
    end
  end
end
