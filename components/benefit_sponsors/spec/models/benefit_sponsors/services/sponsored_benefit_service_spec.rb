require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Services::SponsoredBenefitService, dbclean: :after_each do
  let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
  let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
  let(:benefit_application)    { benefit_sponsorship.benefit_applications.first }
  let(:benefit_package)    { benefit_application.benefit_packages.first }

  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let(:benefit_market)      { site.benefit_markets.first }
  let(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
    issuer_profile: issuer_profile,
    benefit_market: benefit_market,
    title: "SHOP Benefits for #{current_effective_date.year}",
    application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
  }
  let(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
  let(:product_package_kind) { :single_product}
  let(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
  let(:product) { product_package.products.first }
  let(:contribution_model) { product_package.contribution_model }

  let(:employee_contribution_unit) { contribution_model.contribution_units.where(order: 0).first }
  let(:spouse_contribution_unit) { contribution_model.contribution_units.where(order: 1).first }
  let(:partner_contribution_unit) { contribution_model.contribution_units.where(order: 2).first }
  let(:child_contribution_unit) { contribution_model.contribution_units.where(order: 3).first }

  let(:attrs) {
    {
      benefit_package_id: benefit_package.id,
      kind: :dental
    }
  }

  let(:sponsor_contribution_attributes) {
    {
        :contribution_levels_attributes => contribution_levels_attributes
    }
  }

  let(:contribution_levels_attributes) {
    {
        "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => "95", contribution_unit_id: employee_contribution_unit.id },
        "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "85", contribution_unit_id: spouse_contribution_unit.id },
        "2" => {:is_offered => "true", :display_name => "Domestic Partner", :contribution_factor => "75", contribution_unit_id: partner_contribution_unit.id },
        "3" => {:is_offered => "true", :display_name => "Child Under 26", :contribution_factor => "75", contribution_unit_id: child_contribution_unit.id }
    }
  }

  describe "while creating a sponsored benefit" do

    let(:benefits_params) {
      {
        :kind => "dental",
        :benefit_package_id => benefit_package.id,
        :benefit_sponsorship_id => benefit_sponsorship.id,
        :product_option_choice => issuer_profile.id,
        :product_package_kind => product_package_kind,
        :reference_plan_id => product.id,

        :sponsor_contribution_attributes => sponsor_contribution_attributes
      }
    }

    let(:create_form) { BenefitSponsors::Forms::SponsoredBenefitForm.new(benefits_params) }
    let(:subject) { BenefitSponsors::Services::SponsoredBenefitService.new(attrs) }

    it "should not have dental sponsored benefits" do
      expect(benefit_package.dental_sponsored_benefit).to eq nil
    end

    context "#form_params_to_attributes" do

      let(:create_result) { subject.form_params_to_attributes(create_form) }

      it "should not have sponsored benefit id" do
        expect(create_result.keys.include?(:id)).to eq false
      end

      it "should have selected reference_plan_id" do
        expect(create_result[:reference_plan_id]).to eq product.id.to_s
      end

      it "should have selected product_package_kind" do
        expect(create_result[:product_package_kind]).to eq product_package_kind.to_s
      end

      it "should have selected product_option_choice(Issuer legal name)" do
        expect(create_result[:product_option_choice]).to eq issuer_profile.id.to_s
      end

      it "should have contribution_levels_attributes" do
        expect(create_result[:sponsor_contribution_attributes].keys.include?(:contribution_levels_attributes)).to eq true
      end

      it "should have 4 contribution_levels_attributes" do # we always have 4 for dental
        expect(create_result[:sponsor_contribution_attributes][:contribution_levels_attributes][0].size).to eq 4
      end
    end

    context "#save" do

      before do
        subject.save(create_form)
        benefit_package.reload
      end

      it "should create new dental sponsored benefits" do
        expect(benefit_package.dental_sponsored_benefit).not_to eq nil
      end

      it "should create contribution levels for newly created dental sponsored benefits" do
        expect(benefit_package.dental_sponsored_benefit.sponsor_contribution.contribution_levels.size).to eq 4
      end
    end
  end

  describe "while destroying a sponsored benefit" do

    let(:benefits_params) {
      {
        :kind => "dental",
        :benefit_package_id => benefit_package.id,
        :benefit_sponsorship_id => benefit_sponsorship.id,
        :product_option_choice => issuer_profile.id.to_s,
        :product_package_kind => product_package_kind,
        :reference_plan_id => product.id.to_s,
        :sponsor_contribution_attributes => sponsor_contribution_attributes
      }
    }

    let(:form) { BenefitSponsors::Forms::SponsoredBenefitForm.new(benefits_params) }
    let(:subject) { BenefitSponsors::Services::SponsoredBenefitService.new(attrs) }

    context "#destroy" do

      before do
        subject.save(form)
        benefit_package.reload
        update_id_and_destroy(benefit_package, benefits_params)
      end

      it "should remove dental sponsored benefits" do
        benefit_package.reload
        expect(benefit_package.dental_sponsored_benefit).to eq nil
      end

      def update_id_and_destroy(benefit_package, benefits_params)
        updated_params = benefits_params.merge!({id: benefit_package.dental_sponsored_benefit.id})
        updated_form = BenefitSponsors::Forms::SponsoredBenefitForm.new(updated_params)
        subject.destroy(updated_form)
      end
    end
  end

  # describe "while updating a sponsored benefit" do
  #   context "#form_params_to_attributes" do
  #     it "should have sponsored benefit id" do
  #       # TODO
  #     end
  #   end
  #
  #   context "#save" do
  #     it "should update dental sponsored benefits" do
  #       # TODO
  #     end
  #   end
  # end
  #
  describe "#load_employer_estimates" do
    let(:form) do
      instance_double(
        ::BenefitSponsors::Forms::SponsoredBenefitForm
      )
    end
    let(:sponsored_benefit) do
      instance_double(
        ::BenefitSponsors::SponsoredBenefits::SponsoredBenefit,
        benefit_package: benefit_package,
        reference_product: reference_product,
        product_package: product_package
      )
    end
    let(:estimator_cost_service) do
      instance_double(
        ::BenefitSponsors::Services::SponsoredBenefitCostEstimationService
      )
    end
    let(:benefit_package) do
      instance_double(
        ::BenefitSponsors::BenefitPackages::BenefitPackage,
        benefit_sponsor_catalog: nil,
        benefit_application: benefit_application
      )
    end

    let(:benefit_package_id) { "A BENEFIT PACKAGE ID" }

    let(:costs) do
      {
        estimated_total_cost: estimated_total_cost,
        estimated_sponsor_exposure: employer_estimated_exposure,
        estimated_enrollee_minimum: employee_estimated_min_cost,
        estimated_enrollee_maximum: employee_estimated_max_cost
      }
    end

    let(:benefit_application) { double }
    let(:reference_product) { double }
    let(:product_package) { double }

    let(:estimated_total_cost) { 9999 }
    let(:employer_estimated_exposure) { 7777 }
    let(:employee_estimated_min_cost) { 999 }
    let(:employee_estimated_max_cost) { 1234 }

    subject { ::BenefitSponsors::Services::SponsoredBenefitService.new({benefit_package_id: benefit_package_id}) }

    before :each do
      allow(::BenefitSponsors::BenefitPackages::BenefitPackage).to receive(:find).with(benefit_package_id).and_return(benefit_package)
      allow(::BenefitSponsors::Services::SponsoredBenefitCostEstimationService).to receive(:new).and_return(estimator_cost_service)
      allow(estimator_cost_service).to receive(:calculate_estimates_for_package_edit).with(
        benefit_application,
        sponsored_benefit,
        reference_product,
        product_package).and_return(costs)
      allow(form).to receive(:employer_estimated_monthly_cost=).with(employer_estimated_exposure)
      allow(form).to receive(:employer_estimated_min_monthly_cost=).with(employee_estimated_min_cost)
      allow(form).to receive(:employer_estimated_max_monthly_cost=).with(employee_estimated_max_cost)
    end

    it "assigns the employer exposure as the total amount to the form" do
      expect(form).to receive(:employer_estimated_monthly_cost=).with(employer_estimated_exposure)
      subject.load_employer_estimates(form, sponsored_benefit)
    end

    it "assigns the correct employee minimum to the form" do
      expect(form).to receive(:employer_estimated_min_monthly_cost=).with(employee_estimated_min_cost)
      subject.load_employer_estimates(form, sponsored_benefit)
    end

    it "assigns the correct employee maximum to the form" do
      expect(form).to receive(:employer_estimated_max_monthly_cost=).with(employee_estimated_max_cost)
      subject.load_employer_estimates(form, sponsored_benefit)
    end

  end

  describe 'Cost calculations' do
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:product_kinds)  { [:health, :dental] }
    let(:dental_sponsored_benefit) { false }

    let(:aasm_state)              { :draft }
    let(:effective_period)        { current_effective_date..current_effective_date.next_year.prev_day }
    let(:current_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
    let(:sponsored_benefit)       { BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new }

    let(:dental_product_package) { sponsor_catalog.product_packages.by_product_kind(:dental).first }
    let(:dental_reference_product) { dental_product_package.products[0] }

    let(:sponsor_catalog) { initial_application.benefit_sponsor_catalog }

    let(:benefit_market_catalog) { current_benefit_market_catalog }
    let(:product_package) { sponsor_catalog.product_packages.where(package_kind: product_package_kind, product_kind: :dental).first }

    let(:sponsored_benefit_attributes) { {
      benefit_package_id: initial_application.benefit_packages[0].id,
      benefit_application_id: initial_application.id,
      benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
      product_package_kind: "single_product", 
      reference_plan_id: dental_reference_product.id,
      :sponsor_contribution_attributes => sponsor_contribution_attributes,
      kind: "dental"
      } }

    let(:form) { BenefitSponsors::Forms::SponsoredBenefitForm.new(sponsored_benefit_attributes) }
    subject { BenefitSponsors::Services::SponsoredBenefitService.new(sponsored_benefit_attributes) }

    context '.calculate_premiums' do 

      context 'when employer setting up dental sponsored benefit' do

        it "should calculate employer contribution amounts" do 
          subject.load_form_meta_data(form)
          result = subject.calculate_premiums(form)
        end
      end 
    end

    context '.calculate_employee_cost_details' do 

      include_context "setup employees"

      context 'when employer setting up dental sponsored benefit' do

        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:age_bounding).and_return(20)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(15)
        end

        it "should calculate employee cost details" do
          subject.load_form_meta_data(form)
          result = subject.calculate_employee_cost_details(form)
        end
      end
    end
  end
end