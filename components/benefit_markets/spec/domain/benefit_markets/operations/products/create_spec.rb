# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::Products::Create, dbclean: :after_each do

  let(:effective_date)          { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:application_period)      { effective_date..(effective_date + 1.year).prev_day }
  let(:pricing_units)           { [{name: 'name', display_name: 'Employee Only', order: 1}] }
  let(:premium_tuples)          { {age: 12, cost: 227.07} }
  let(:effective_period)        { effective_date.beginning_of_year..effective_date.end_of_year }
  let(:premium_tables)          { [{effective_period: effective_period, premium_tuples: [premium_tuples], rating_area_id: BSON::ObjectId.new}] }
  let(:member_relationships)    { [{relationship_name: :employee, relationship_kinds: ['self'], age_threshold: 18, age_comparison: :==, disability_qualifier: true}] }

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
      title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format', language: 'language', type: 'type', source: 'source'
    }
  end

  let(:product_params) do
    {
      _id: BSON::ObjectId.new, hios_id: '9879', hios_base_id: '34985', metal_level_kind: :silver,
      ehb: 0.9, is_standard_plan: true, hsa_eligibility: true, csr_variant_id: '01', health_plan_kind: :health_plan_kind,
      benefit_market_kind: :benefit_market_kind, application_period: application_period, kind: :health,
      hbx_id: 'hbx_id', title: 'title', description: 'description', product_package_kinds: [:product_package_kinds],
      issuer_profile_id: BSON::ObjectId.new, premium_ages: 19..60, provider_directory_url: 'provider_directory_url',
      is_reference_plan_eligible: true, deductible: '123', family_deductible: '345', rx_formulary_url: 'rx_formulary_url',
      issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information',
      nationwide: true, dc_in_network: false, sbc_document: sbc_document, premium_tables: premium_tables
    }
  end

  let(:params)                  { {product_params: product_params} }

  context 'sending required parameters' do

    it 'should create Product' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success).to be_a BenefitMarkets::Entities::Product
    end
  end
end

