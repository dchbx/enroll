# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::SponsoredBenefits::SponsoredBenefitsController, type: :controller, dbclean: :after_each do

  routes { BenefitSponsors::Engine.routes }

  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, :person => person)}
  let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:benefit_sponsor)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
  let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
  let(:benefit_application)    { benefit_sponsorship.benefit_applications.first }
  let(:benefit_package)    { benefit_application.benefit_packages.first }
  let(:sponsored_benefits_id)   { benefit_package.sponsored_benefits.first.id}

  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let(:benefit_market)      { site.benefit_markets.first }
  let(:benefit_market_catalog) do
    create(:benefit_markets_benefit_market_catalog, :with_product_packages,
           benefit_market: benefit_market,
           title: "SHOP Benefits for #{current_effective_date.year}",
           application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
  end
  let(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
  let(:product_package_kind) { :single_product }
  let(:sponsored_benefit_kind) { "dental" }
  let(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind, product_kind: sponsored_benefit_kind).first }
  let(:product) { product_package.products.first }

  let(:benefits_params) do
    {
      :kind => sponsored_benefit_kind,
      :benefit_application_id => benefit_application.id,
      :benefit_package_id => benefit_package.id,
      :benefit_sponsorship_id => benefit_sponsorship.id,
      :sponsored_benefit_attributes => sponsored_benefits_params
    }
  end

  let(:sponsored_benefits_params) do
    {
      :sponsor_contribution_attributes => sponsor_contribution_attributes,
      :product_package_kind => product_package_kind,
      :kind => sponsored_benefit_kind,
      :product_option_choice => issuer_profile.legal_name,
      :reference_plan_id => product.id.to_s
    }
  end

  let(:sponsor_contribution_attributes) do
    {
      :contribution_levels_attributes => contribution_levels_attributes
    }
  end

  let(:contribution_levels_attributes) do
    {
      "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => "95", contribution_unit_id: employee_contribution_unit.id },
      "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "85", contribution_unit_id: spouse_contribution_unit.id},
      "2" => {:is_offered => "true", :display_name => "Domestic Partner", :contribution_factor => "75", contribution_unit_id: partner_contribution_unit.id },
      "3" => {:is_offered => "true", :display_name => "Child Under 26", :contribution_factor => "75", contribution_unit_id: child_contribution_unit.id }
    }
  end

  let(:contribution_model) { product_package.contribution_model }

  let(:employee_contribution_unit) { contribution_model.contribution_units.where(order: 0).first }
  let(:spouse_contribution_unit) { contribution_model.contribution_units.where(order: 1).first }
  let(:partner_contribution_unit) { contribution_model.contribution_units.where(order: 2).first }
  let(:child_contribution_unit) { contribution_model.contribution_units.where(order: 3).first }

  describe "GET new", dbclean: :after_each do

    context "when a user having right permissions signed in" do

      before :each do
        sign_in user
        get :new, params: {benefit_package_id: benefit_package.id, benefit_application_id: benefit_application.id, benefit_sponsorship_id: benefit_sponsorship.id, kind: sponsored_benefit_kind}
      end

      it "should render new template" do
        expect(response).to render_template("new")
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "when a user not having valid permissions signed in" do

      it "should not render new template" do
      end

      it "should redirect to xxxxx " do
      end
    end
  end

  describe "POST create", dbclean: :after_each do

    context "when a user having right permissions signed in" do

      before :each do
        sign_in user
        post :create, params: {benefit_package_id: benefit_package.id, benefit_application_id: benefit_application.id, benefit_sponsorship_id: benefit_sponsorship.id, sponsored_benefits: sponsored_benefits_params}
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should redirect to benefits tab" do
        expect(response.location.include?("tab=benefits")).to eq true
      end
    end

    context "when a user not having valid permissions signed in" do

      it "should redirect to xxxxx " do
      end
    end
  end

  describe "GET edit" do

    let(:benefits_params) do
      {
        :kind => sponsored_benefit_kind,
        :benefit_application_id => benefit_application.id,
        :benefit_package_id => benefit_package.id,
        :benefit_sponsorship_id => benefit_sponsorship.id,
        :product_option_choice => issuer_profile.legal_name,
        :product_package_kind => product_package_kind,
        :reference_plan_id => product.id.to_s,
        :sponsor_contribution_attributes => sponsor_contribution_attributes
      }
    end

    before :each do
      sign_in user
      sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_create(benefits_params)
      allow(BenefitSponsors::Forms::SponsoredBenefitForm).to receive(:for_edit) { sponsored_benefit_form }
      get :edit, params: {id: sponsored_benefit_form.service.package.id, benefit_package_id: benefit_package.id, benefit_application_id: benefit_application.id, benefit_sponsorship_id: benefit_sponsorship.id, kind: sponsored_benefit_kind}
    end

    it "should render edit template" do
      expect(response).to render_template("edit")
    end

    it "should return http success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST update" do
    let(:benefits_params) do
      {
        :kind => sponsored_benefit_kind,
        :benefit_application_id => benefit_application.id,
        :benefit_package_id => benefit_package.id,
        :benefit_sponsorship_id => benefit_sponsorship.id,
        :product_option_choice => issuer_profile.legal_name,
        :product_package_kind => product_package_kind,
        :reference_plan_id => product.id.to_s,
        :sponsor_contribution_attributes => sponsor_contribution_attributes
      }
    end

    before :each do
      sign_in user
      @sponsored_benefit_form = BenefitSponsors::Forms::SponsoredBenefitForm.for_create(benefits_params)
      allow_any_instance_of(BenefitSponsors::Forms::SponsoredBenefitForm).to receive(:update){true}
      put :update, params: {id: @sponsored_benefit_form.service.package.id, benefit_package_id: benefit_package.id, benefit_application_id: benefit_application.id, benefit_sponsorship_id: benefit_sponsorship.id, sponsored_benefits: sponsored_benefits_params}
    end

    it "should have flash notice" do
      expect(request.flash[:notice]).to_not be_nil
    end

    it "should redirect" do
      expect(response).to be_redirect
    end
  end

  describe "DELETE destroy", dbclean: :after_each do

    let(:benefits_params) do
      {
        :kind => sponsored_benefit_kind,
        :benefit_application_id => benefit_application.id,
        :benefit_package_id => benefit_package.id,
        :benefit_sponsorship_id => benefit_sponsorship.id,
        :id => sponsored_benefits_id
      }
    end

    before :each do
      sign_in user
      delete :destroy, params: benefits_params
    end

    it "should redirect" do
      expect(response).to have_http_status(:redirect)
    end

    it "should redirect to edit page of benefit_sponsor" do
      expect(response).to redirect_to(profiles_employers_employer_profile_path(benefit_sponsor.employer_profile, :tab => 'benefits'))
      expect(response.location.include?("benefits")).to eq true
    end

    it "should get an notice" do
      expect(flash[:notice]).to match /Dental Benefit Package successfully deleted/
    end

  end
end
