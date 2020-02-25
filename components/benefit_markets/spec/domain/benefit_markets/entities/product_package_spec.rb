# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::ProductPackage do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitMarkets::Validators::Products::ProductPackageContract.new }

    let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:application_period)        { effective_date..(effective_date + 1.year).prev_day }

    let(:premium_ages)              { 16..40 }

    let(:pricing_units)             { [{name: 'name', display_name: 'Employee Only', order: 1}] }
    let(:member_relationships)      { [{relationship_name: :employee, relationship_kinds: [{}], age_threshold: 18, age_comparison: :==, disability_qualifier: true}] }
    let(:pricing_model) do
      {
        name: 'name', price_calculator_kind: 'price_calculator_kind', pricing_units: pricing_units,
        product_multiplicities: [:product_multiplicities], member_relationships: member_relationships
      }
    end

    let(:contribution_unit) do
      {
        name: "Employee",
        display_name: "Employee Only",
        order: 1,
        member_relationship_maps: [relationship_name: :employee, operator: :==, count: 1]
      }
    end

    let(:contribution_model) do
      {
        title: 'title', key: :key, sponsor_contribution_kind: 'sponsor_contribution_kind', contribution_calculator_kind: 'contribution_calculator_kind',
        many_simultaneous_contribution_units: true, product_multiplicities: [:product_multiplicities1, :product_multiplicities2],
        member_relationships: member_relationships, contribution_units: [contribution_unit]
      }
    end

    let(:sbc_document) do
      {
        title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format',
        language: 'language', type: 'type', source: 'source'
      }
    end

    let(:premium_tuples)   { {age: 12, cost: 227.07} }
    let(:effective_period)    { effective_date.beginning_of_year..effective_date.end_of_year }

    let(:premium_tables)   { [{effective_period: effective_period, rating_area_id: BSON::ObjectId.new, premium_tuples: [premium_tuples]}] }

    let(:product) do
      {
        benefit_market_kind: :benefit_market_kind, application_period: application_period, kind: :kind,
        hbx_id: 'hbx_id', title: 'title', description: 'description', product_package_kinds: [:product_package_kinds],
        issuer_profile_id: BSON::ObjectId.new, premium_ages: premium_ages, provider_directory_url: 'provider_directory_url',
        is_reference_plan_eligible: true, deductible: 'deductible', family_deductible: 'family_deductible',
        issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information',
        nationwide: true, dc_in_network: false, sbc_document: sbc_document, premium_tables: premium_tables
      }
    end

    let(:required_params) do
      {
        application_period: application_period, benefit_kind: :benefit_kind, product_kind: :product_kind, package_kind: :package_kind,
        title: 'Title', products: [product], contribution_model: contribution_model, contribution_models: [contribution_model],
        pricing_model: pricing_model
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new ProductPackage instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::ProductPackage
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end

    context "with all params" do
      let(:all_params) {required_params.merge({description: 'description', assigned_contribution_model: contribution_model})}

      it "contract validation should pass" do
        expect(contract.call(all_params).to_h).to eq all_params
      end

      it "should create new ProductPackage instance" do
        expect(described_class.new(all_params)).to be_a BenefitMarkets::Entities::ProductPackage
        expect(described_class.new(all_params).to_h).to eq all_params
      end
    end
  end
end