# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::Product do

  context "Given valid required parameters" do

    let(:contract)           { BenefitMarkets::Validators::Products::ProductContract.new }

    let(:premium_tuples)     { {age: 12, cost: 227.07} }
    let(:effective_period)   { effective_date.beginning_of_year..effective_date.end_of_year }
    let(:premium_tables)     { [{effective_period: effective_period, rating_area_id: BSON::ObjectId.new, premium_tuples: [premium_tuples]}] }
    let(:required_params)    { {relationship_name: :employee, relationship_kinds: [{}]} }

    let(:effective_date)     { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:application_period) { effective_date..(effective_date + 1.year).prev_day }

    let(:premium_ages)       { 16..40 }

    let(:sbc_document) do
      {
        title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format', tags: [{}],
        language: 'language', type: 'type', source: 'source', subject: 'subject', identifier: 'identifier'
      }
    end
    let(:required_params) do
      {
        benefit_market_kind: :benefit_market_kind, application_period: application_period, kind: :kind, hbx_id: 'hbx_id', title: 'title',
        product_package_kinds: [:product_package_kinds], provider_directory_url: 'provider_directory_url', issuer_profile_id:  BSON::ObjectId.new,
        premium_ages: premium_ages, is_reference_plan_eligible: true, deductible: 'deductible', family_deductible: 'family_deductible',
        issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information', nationwide: true,
        dc_in_network: false, sbc_document: sbc_document, premium_tables: premium_tables
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new Product instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::Product
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end

    context "with all params" do
      let(:all_params) {required_params.merge({description: 'description'})}

      it "contract validation should pass" do
        expect(contract.call(all_params).to_h).to eq all_params
      end

      it "should create new Product instance" do
        expect(described_class.new(all_params)).to be_a BenefitMarkets::Entities::Product
        expect(described_class.new(all_params).to_h).to eq all_params
      end
    end
  end
end