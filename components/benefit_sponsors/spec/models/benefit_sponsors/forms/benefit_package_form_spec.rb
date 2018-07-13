require 'rails_helper'

module BenefitSponsors
  RSpec.describe Forms::BenefitPackageForm, type: :model, dbclean: :after_each do

    let(:form_class)              { BenefitSponsors::Forms::BenefitPackageForm }
    let(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :as_hbx_profile, :cca) }
    let(:benefit_market)          { site.benefit_markets.first }
    let(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }

    let(:organization)          { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)      { organization.employer_profile }
    let(:employer_attestation)  { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship)   { employer_profile.add_benefit_sponsorship }
    let(:benefit_application)   {
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship)
      application.benefit_sponsor_catalog.save!
      application
    }
    let!(:product_package_kind)     { :single_issuer }
    let!(:product_package)          { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
    let!(:product)                  { product_package.products.first }
    let!(:issuer_profile)           { FactoryGirl.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site }

    after :all do
      DatabaseCleaner.clean
    end

    shared_context "valid params", :shared_context => :metadata do
      let(:benefit_package_params) {
        {
          :benefit_application_id => benefit_application.id.to_s,
          :title => "New Benefit Package",
          :description => "New Model Benefit Package",
          :probation_period_kind => "first_of_month",
          :sponsored_benefits_attributes => sponsored_benefits_params
        }
      }

      let(:sponsored_benefits_params) {
        {
          "0" => {
            :sponsor_contribution_attributes => sponsor_contribution_attributes,
            :product_package_kind => product_package_kind,
            :kind => "health",
            :product_option_choice => issuer_profile.legal_name,
            :reference_plan_id => product.id.to_s
          }
        }
      }

      let(:sponsor_contribution_attributes) {
        {
          :contribution_levels_attributes => contribution_levels_attributes
        }
      }

      let(:contribution_levels_attributes) {
        {
          "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => "0.95"},
          "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "0.85"},
          "2" => {:is_offered => "true", :display_name => "Dependent", :contribution_factor => "0.75"}
        }
      }
    end

    shared_context "invalid params", :shared_context => :metadata do
      let(:benefit_package_params) {
        {
          :benefit_application_id => nil,
          :title => nil,
          :description => "New Model Benefit Package",
          :probation_period_kind => "first_of_month",
          :sponsored_benefits_attributes => sponsored_benefits_params
        }
      }

      let(:sponsored_benefits_params) {
        {
          "0" => {
            :sponsor_contribution_attributes => sponsor_contribution_attributes,
            :product_package_kind => product_package_kind,
            :kind => "health",
            :product_option_choice => issuer_profile.legal_name,
            :reference_plan_id => product.id.to_s
          }
        }
      }

      let(:sponsor_contribution_attributes) {
        {
          :contribution_levels_attributes => invalid_contribution_levels_attributes
        }
      }

      let(:invalid_contribution_levels_attributes) {
        {
          "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => nil},
          "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "0.85"},
          "2" => {:is_offered => "true", :display_name => "Dependent", :contribution_factor => "0.75"}
        }
      }
    end

    before do
      issuer_profile.organization.update_attributes!(site_id: site.id)
    end

    describe "validate form" do
      context "valid params" do
        include_context "valid params"

        let(:form) {BenefitSponsors::Forms::BenefitPackageForm.new(benefit_package_params)}

        it "should return true" do
          expect(form.valid?).to be_truthy
        end
      end

      context "invalid params" do
        include_context "invalid params"

        let(:form) {BenefitSponsors::Forms::BenefitPackageForm.new(benefit_package_params)}

        it "should return false" do
          expect(form.valid?).to be_falsey
        end

        it "should return errors " do
          form.valid?
          expect(form.errors.full_messages.flatten.sort).to eq ["Contribution factor can't be blank", "Title can't be blank"]
        end
      end
    end

    describe "#for_new" do

      let(:benefit_application_id)  { benefit_application.id.to_s }
      subject { BenefitSponsors::Forms::BenefitPackageForm.for_new(benefit_application_id) }

      it 'instantiates a new Benefit Package Form' do
        expect(subject).to be_an_instance_of(form_class)
      end

      it "instantiates service" do
        expect(subject.service).to be_instance_of(BenefitSponsors::Services::BenefitPackageService)
      end

      it "should assign benefit application" do
        expect(subject.benefit_application_id).to eq benefit_application_id
      end
    end

    describe "#for_create" do
      include_context 'valid params'

      subject { BenefitSponsors::Forms::BenefitPackageForm.for_create benefit_package_params }

      it "should create the form with correct variables" do
        expect(subject.title).to eq benefit_package_params[:title]
        expect(subject.description).to eq benefit_package_params[:description]
        expect(subject.probation_period_kind).to eq benefit_package_params[:probation_period_kind].to_sym
      end

      it 'creates a new benefit package object when saved' do
        subject.save
        benefit_application.reload
        expect(benefit_application.benefit_packages.present?).to be_truthy
      end
    end

    describe '#for_edit' do

      include_context 'valid params'

      let(:benefit_application_id)  { benefit_application.id.to_s }
      let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
      let(:params_for_edit)  {
        {
          "id" => benefit_package.id.to_s,
          "benefit_application_id" => benefit_application_id
        }
      }

      before do
        benefit_package.sponsored_benefits.first.reference_product.update_attributes!(:issuer_profile_id => issuer_profile.id)
        benefit_package.reload
      end

      subject { BenefitSponsors::Forms::BenefitPackageForm.for_edit(params_for_edit, false) }

      it 'loads the existing Site in to the Site Form' do
        expect(subject.title).to eql(benefit_package.title)
      end
    end

    describe '#for_update' do

      include_context 'valid params'

      let(:contribution_levels)    { benefit_package.sponsored_benefits[0].sponsor_contribution.contribution_levels }
      let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
      let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
      let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }

      subject { BenefitSponsors::Forms::BenefitPackageForm.for_update benefit_package_params.merge({:id => benefit_package.id.to_s}) }

      before do
        sponsored_benefits_params["0"].merge!({
          :id => benefit_package.sponsored_benefits[0].id.to_s,
        })

        contribution_levels_attributes.each do |k, v|
          cl = contribution_levels.where(:display_name => v[:display_name].to_s).first
          v.merge!({ :id => cl.id.to_s })
        end

        subject.update
        benefit_application.reload
      end


      it "updates the benefit package model's title" do
        expect(benefit_application.benefit_packages[0].title).to eql(benefit_package_params[:title])
      end

      it "updates the form's title" do
        expect(subject.title).to eql(benefit_package_params[:title])
      end
    end

  end

end
