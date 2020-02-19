# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::SponsoredBenefits::SponsoredBenefitContract do

  let(:product_package_kind)       { :product_package_kind }
  let(:product_option_choice)      { 'product_option_choice' }
  let(:source_kind)                { :source_kind }

  let(:contribution_level) do
    {
      display_name: 'Employee Only', order: 1, contribution_unit_id: 'contribution_unit_id',
      is_offered: true, contribution_factor: 0.75, min_contribution_factor: 0.5,
      contribution_cap: 0.75, flat_contribution_amount: 227.07
    }
  end
  let(:contribution_levels)        { [contribution_level] }
  let(:sponsor_contribution)       { {contribution_levels: contribution_levels} }

  let(:pricing_determination)     { {group_size: 4, participation_rate: 75, pricing_determination_tiers: [{pricing_unit_id: 'pricing_unit_id', price: 227.07}]} }
  let(:pricing_determinations)     { [pricing_determination] }

  let(:missing_params)   { {product_package_kind: product_package_kind, product_option_choice: product_option_choice, source_kind: source_kind, pricing_determinations: pricing_determinations} }
  let(:invalid_params)   { missing_params.merge({sponsor_contribution: {} })}
  let(:error_message1)   { {:reference_product => ["is missing"], :sponsor_contribution => ["is missing"]} }
  let(:error_message2)   { {:reference_product => ["is missing"], :sponsor_contribution => ["must be filled"]} }

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
      let(:effective_date)                { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:application_period)            { effective_date..(effective_date + 1.year).prev_day }
      let(:premium_ages)                  { [1..15, 16..40]}

      let(:sbc_document) do
        {
          title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format',
          language: 'language', type: 'type', source: 'source'
        }
      end

      let(:premium_tuples)   { {age: 12, cost: 227.07} }
      let(:rating_area)      { {active_year: effective_date.year, exchange_provided_code: 'code', county_zip_ids: [{}], covered_states: [{}]} }

      let(:premium_tables)   { [{effective_period: effective_date.beginning_of_year..(effective_date.end_of_year), premium_tuples: [premium_tuples], rating_area: rating_area}] }

      let(:reference_product) do
        {
          benefit_market_kind: :benefit_market_kind, application_period: application_period, kind: :kind,
          hbx_id: 'hbx_id', title: 'title', description: 'description', product_package_kinds: [:product_package_kinds],
          issuer_profile_id: BSON::ObjectId.new, premium_ages: premium_ages, provider_directory_url: 'provider_directory_url',
          is_reference_plan_eligible: true, deductible: 'deductible', family_deductible: 'family_deductible',
          issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information',
          nationwide: true, dc_in_network: false, sbc_document: sbc_document, premium_tables: premium_tables
        }
      end

      let(:all_params) { missing_params.merge({reference_product: reference_product, sponsor_contribution: sponsor_contribution}) }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end