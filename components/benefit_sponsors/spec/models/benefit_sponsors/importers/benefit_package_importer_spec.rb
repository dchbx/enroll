require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors::Importers
  RSpec.describe BenefitPackageImporter, dbclean: :after_each do

    before :each do
      DatabaseCleaner.clean
    end

    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let(:current_effective_date) { Date.new(2019, 1, 1) }
    let(:aasm_state) { :draft }
    let(:package_kind) { :metal_level }

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:benefit_group_params) {
      { title: "Benefit Group Created for: First Prospect by TestAgency",
        description: "Sample benefit group",
        effective_on_kind: "first_of_month",
        effective_on_offset: 0
      }.merge(offerings)
    }

    let(:offerings) { health_benefit_params }

    let(:health_benefit_params) {
      {
        plan_option_kind: "metal_level",
        relationship_benefits: relationship_benefits,
        reference_plan_hios_id: reference_plan.hios_id
      }
    }


    let(:reference_plan) do
      BenefitMarkets::Products::Product.where(
        "application_period.min" => current_benefit_market_catalog.application_period.min,
        :_type => /Health/i
      ).first
    end

    let(:product_kinds)  { [:health, :dental] }
    let(:catalog_dental_package_kinds) { [:multi_product] }

    let(:new_application) {
      current_benefit_market_catalog
      application = benefit_sponsorship.benefit_applications.new(
        effective_period: (current_effective_date..current_effective_date.next_year.prev_day)
        )
      application.pull_benefit_sponsorship_attributes
      application.benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(application.effective_period.begin)
      catalog = application.benefit_sponsor_catalog
      catalog.benefit_application = application
      catalog.save
      application
    }

    let(:relationship_benefits) {
      [
        {"premium_pct"=>90.0, "offered"=>true, "relationship"=>"employee"},
        {"premium_pct"=>80.0, "offered"=>true, "relationship"=>"spouse"},
        {"premium_pct"=>0.0, "offered"=>true, "relationship"=>"domestic_partner"},
        {"premium_pct"=>0.0, "offered"=>true, "relationship"=>"child_under_26"},
        {"premium_pct"=>0.0, "offered"=>true, "relationship"=>"child_26_and_over"}
      ]
    }

    subject { BenefitSponsors::Importers::BenefitPackageImporter.call(new_application, benefit_group_params) }

    describe "when only health attributes given" do
      context "will build benefit package with health benefits" do

        it "should have health sponsored benefit" do
          expect(subject.benefit_package.sponsored_benefits.size).to eq 1
          expect(subject.benefit_package.health_sponsored_benefit.present?).to be_truthy
        end

        it "should have correct reference product" do
          expect(subject.benefit_package.health_sponsored_benefit.reference_product).to eq reference_plan
        end

        it "should map to correct product package kind" do
          expect(subject.benefit_package.health_sponsored_benefit.product_package.package_kind).to eq :metal_level
        end

        it "should map to correct product kind" do
          expect(subject.benefit_package.health_sponsored_benefit.product_package.product_kind).to eq :health
        end
      end
    end

    describe "when both health and dental attributes given", dbclean: :after_each do
      let(:offerings) { health_benefit_params.merge(dental_benefit_params) }

      let(:dental_benefit_params) {
        {
          dental_plan_option_kind: "single_plan",
          dental_reference_plan_hios_id: dental_reference_plan.hios_id,
          dental_relationship_benefits: dental_relationship_benefits,
          elected_dental_plan_hios_ids: dental_hios_ids
        }
      }

      let(:dental_hios_ids) do
        BenefitMarkets::Products::Product.where(
          "application_period.min" => current_benefit_market_catalog.application_period.min,
          :_type => /Dental/i
        ).pluck(:hios_id)
      end

      let(:dental_reference_plan) do
        BenefitMarkets::Products::Product.where(
          "application_period.min" => current_benefit_market_catalog.application_period.min,
          :_type => /Dental/i,
          "product_package_kinds" => "multi_product"
        ).first
      end

      let(:dental_relationship_benefits) {
        [
          {"premium_pct"=>100.0, "offered"=>true, "relationship"=>"employee"},
          {"premium_pct"=>0.0, "offered"=>true, "relationship"=>"spouse"},
          {"premium_pct"=>0.0, "offered"=>false, "relationship"=>"domestic_partner"},
          {"premium_pct"=>0.0, "offered"=>false, "relationship"=>"child_under_26"},
          {"premium_pct"=>0.0, "offered"=>false, "relationship"=>"child_26_and_over"}
        ]
      }

      context "will build benefit package with health and dental benefits" do
        it "should have both health and dental sponsored benefits" do
          expect(subject.benefit_package.sponsored_benefits.size).to eq 2
          expect(subject.benefit_package.dental_sponsored_benefit.present?).to be_truthy
        end

        it "should have correct reference product" do
          expect(subject.benefit_package.dental_sponsored_benefit.reference_product).to eq dental_reference_plan
        end

        it "should map to correct product package kind" do
          expect(subject.benefit_package.dental_sponsored_benefit.product_package.package_kind).to eq :multi_product
        end

        it "should map to correct product kind" do
          expect(subject.benefit_package.dental_sponsored_benefit.product_package.product_kind).to eq :dental
        end
      end
    end
  end
end
