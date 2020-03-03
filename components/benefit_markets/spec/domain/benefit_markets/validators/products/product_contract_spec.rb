# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Products::ProductContract do

  let(:benefit_market_kind)           { :benefit_market_kind }
  let(:effective_date)                { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:effective_period)              { effective_date.beginning_of_year..(effective_date.end_of_year) }
  let(:application_period)            { effective_date..(effective_date + 1.year).prev_day }
  let(:hbx_id)                        { 'Hbx id'}
  let(:title)                         { 'Title' }
  let(:description)                   { 'Description' }
  let(:issuer_profile_id)             { BSON::ObjectId.new }
  let(:product_package_kinds)         { [:product_package_kinds] }
  let(:kind)                          { :health }
  let(:provider_directory_url)        { 'provider_directory_url' }
  let(:is_reference_plan_eligible)    { true }
  let(:deductible)                    { 'deductible' }
  let(:family_deductible)             { 'family_deductible' }
  let(:issuer_assigned_id)            { 'issuer_assigned_id' }
  let(:service_area_id)               { BSON::ObjectId.new }
  let(:network_information)           { 'network_information'}
  let(:nationwide)                    { true }
  let(:dc_in_network)                 { false }
  let(:id)                            { BSON::ObjectId.new }
  let(:hsa_eligibility)               { true }

  let(:sbc_document) do
    {
      title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format',
      language: 'language', type: 'type', source: 'source'
    }
  end

  let(:premium_tables)   { [{effective_period: effective_period, rating_area_id: BSON::ObjectId.new}] }
  let(:missing_params) do
    {
      _id: id,
      benefit_market_kind: benefit_market_kind, application_period: application_period,
      hbx_id: hbx_id, title: title, description: description, product_package_kinds: product_package_kinds,
      issuer_profile_id: issuer_profile_id, premium_ages: 19..60, provider_directory_url: provider_directory_url,
      is_reference_plan_eligible: is_reference_plan_eligible, deductible: deductible, family_deductible: family_deductible,
      issuer_assigned_id: issuer_assigned_id, service_area_id: service_area_id, network_information: network_information,
      nationwide: nationwide, dc_in_network: dc_in_network, sbc_document: sbc_document
    }
  end

  let(:invalid_params)      { missing_params.merge({kind: kind, premium_tables: 'premium_tables'}) }
  let(:error_message1)      { {:premium_tables => ["is missing"], :kind => ["is missing"]} }
  let(:error_message2)      { {:premium_tables => ["must be an array"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do
    context "with all/required params" do
      let(:premium_tuples)   { {age: 12, cost: 227.07} }

      let(:premium_tables)   { [{effective_period: effective_period, premium_tuples: [premium_tuples], rating_area_id: BSON::ObjectId.new}] }
      let(:all_params)       { missing_params.merge({kind: kind, premium_tables: premium_tables })}

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end