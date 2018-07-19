require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::BenefitApplicationService, type: :model, :dbclean => :after_each do

    describe "constructor" do
      let(:benefit_sponser_ship) { double("BenefitSponsorship", {
          :benefit_market => "BenefitMarket",
          :profile_id => "rspec-id",
          :organization => "Organization"
      })}
      let(:benefit_factory) { double("BenefitApplicationFactory", benefit_sponser_ship: benefit_sponser_ship) }

      it "should initialize service factory" do
        service_obj = Services::BenefitApplicationService.new(benefit_factory)
        expect(service_obj.benefit_application_factory).to eq benefit_factory
      end
    end

    describe ".store service" do

      let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
      let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
      let(:effective_period)          { effective_period_start_on..effective_period_end_on }

      let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
      let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) do
        {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period,
        }
      end

      let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }

      let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application) }
      let!(:invalid_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new}
      let!(:invalid_benefit_application) { BenefitSponsors::BenefitApplications::BenefitApplication.new }

      let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
      let!(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:benefit_sponsorship) do
        FactoryGirl.create(
          :benefit_sponsors_benefit_sponsorship,
          :with_rating_area,
          :with_service_areas,
          supplied_rating_area: rating_area,
          service_area_list: [service_area],
          organization: organization,
          profile_id: organization.profiles.first.id,
          benefit_market: site.benefit_markets[0],
          employer_attestation: employer_attestation)
      end
      let(:benefit_application)       { benefit_sponsorship.benefit_applications.new(params) }

      let!(:benefit_market) { site.benefit_markets.first }
      let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }

      let!(:benefit_application_factory) { BenefitSponsors::BenefitApplications::BenefitApplicationFactory }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      context "has received valid attributes" do
        it "should save updated benefit application" do
          allow(benefit_market).to receive(:benefit_sponsor_catalog_for).with([],benefit_application.effective_period.begin).and_return(nil)
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          expect(service_obj.store(benefit_application_form, benefit_application)).to eq [true, benefit_application]
        end
      end

      context "has received invalid attributes" do
        it "should map the errors to benefit application" do
          allow(benefit_application_factory).to receive(:validate).with(invalid_benefit_application).and_return false
          expect(invalid_application_form.valid?).to be_falsy
          expect(invalid_benefit_application.valid?).to be_falsy
          # TODO: add expectations to match the errors instead of counts
          # expect(invalid_application_form.errors.count).to eq 4
          service_obj = Services::BenefitApplicationService.new(benefit_application_factory)
          expect(service_obj.store(invalid_application_form, invalid_benefit_application)).to eq [false, nil]
          # expect(invalid_application_form.errors.count).to eq 8
        end
      end
    end

    describe ".load_form_metadata" do
      let(:benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new }
      let(:subject) { BenefitSponsors::Services::BenefitApplicationService.new }
      it "should assign attributes of benefit application to form" do
        subject.load_form_metadata(benefit_application_form)
        expect(benefit_application_form.start_on_options).not_to be nil
      end
    end

    describe ".load_form_params_from_resource" do
      let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
      let!(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
      let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
      let!(:benefit_market) { site.benefit_markets.first }

      let(:benefit_sponsorship) do
        FactoryGirl.create(
          :benefit_sponsors_benefit_sponsorship,
          :with_rating_area,
          :with_service_areas,
          supplied_rating_area: rating_area,
          service_area_list: [service_area],
          organization: organization,
          profile_id: organization.profiles.first.id,
          benefit_market: benefit_market,
          employer_attestation: employer_attestation)
      end

      let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
      let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application, id: benefit_application.id ) }
      let(:subject) { BenefitSponsors::Services::BenefitApplicationService.new }

      it "should assign the form attributes from benefit application" do
         form = subject.load_form_params_from_resource(benefit_application_form)
         expect(form[:start_on]).to eq benefit_application.start_on.to_date.to_s
         expect(form[:end_on]).to eq benefit_application.end_on.to_date.to_s
         expect(form[:open_enrollment_start_on]).to eq benefit_application.open_enrollment_start_on.to_date.to_s
         expect(form[:open_enrollment_end_on]).to eq benefit_application.open_enrollment_end_on.to_date.to_s
         expect(form[:pte_count]).to eq benefit_application.pte_count
         expect(form[:msp_count]).to eq benefit_application.msp_count
      end
    end

    # describe ".publish" do
    #   let(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_full_package)}
    #   let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, benefit_sponsorship: benefit_sponsorship) }
    #   let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application, id: benefit_application.id ) }
    #   let(:subject) { BenefitSponsors::Services::BenefitApplicationService.new }
    #
    #   context "has to publish and " do
    #     it "Should validate " do
    #       allow(benefit_sponsorship.profile).to receive(:is_primary_office_local?).and_return true
    #       subject.publish(benefit_application_form)
    #
    #
    #     end
    #   end
    # end

  end
end
