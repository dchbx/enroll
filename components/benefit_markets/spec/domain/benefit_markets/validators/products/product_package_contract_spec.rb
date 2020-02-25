# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Products::ProductPackageContract do

  let(:effective_date)                { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:application_period)            { effective_date..(effective_date + 1.year).prev_day }
  let(:benefit_kind)                  { :benefit_kind }
  let(:product_kind)                  { :product_kind}
  let(:package_kind)                  { :package_kind }
  let(:title)                         { 'Title' }
  let(:description)                   { 'Description' }

  let(:pricing_units)                 { [{name: 'name', display_name: 'Employee Only', order: 1}] }
  let(:member_relationships)          { [{relationship_name: :employee, relationship_kinds: ['self'], age_threshold: 18, age_comparison: :==, disability_qualifier: true}] }
  let(:pricing_model) do
    {
      name: 'name', price_calculator_kind: 'price_calculator_kind', pricing_units: pricing_units,
      product_multiplicities: [:product_multiplicities], member_relationships: member_relationships
    }
  end

  let(:member_relationship_map)       { ::BenefitMarkets::ContributionModels::MemberRelationshipMap.new(relationship_name: 'Employee', count: 1).as_json }
  let(:member_relationship_maps)      { [member_relationship_map] }
  let(:contribution_unit) do
    ::BenefitMarkets::ContributionModels::ContributionUnit.new(
      name: "Employee",
      display_name: "Employee Only",
      order: 1,
      member_relationship_maps: member_relationship_maps
    )
  end

  let(:contribution_units)            { [contribution_unit.as_json] }

  let(:contribution_model) do
    {
      title: 'title', key: :key, sponsor_contribution_kind: 'sponsor_contribution_kind', contribution_calculator_kind: 'contribution_calculator_kind',
      many_simultaneous_contribution_units: true, product_multiplicities: [:product_multiplicities1, :product_multiplicities2],
      member_relationships: member_relationships, contribution_units: contribution_units
    }
  end
  let(:contribution_models)           { [contribution_model] }
  let(:assigned_contribution_model)   { contribution_model  }

  let(:missing_params)   { {application_period: application_period, benefit_kind: benefit_kind, product_kind: product_kind, package_kind: package_kind, title: title} }
  let(:invalid_params)   { missing_params.merge({pricing_model: {}, contribution_model: contribution_model, contribution_models: contribution_models })}
  let(:error_message1)   { {:products => ["is missing"], :pricing_model => ["is missing"], :contribution_model => ["is missing"], :contribution_models => ["is missing"] } }
  let(:error_message2)   { {:pricing_model => ["must be filled"], :products => ["is missing"]} }

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

    let(:sbc_document) do
      {
        title: 'title', creator: 'creator', publisher: 'publisher', format: 'file_format',
        language: 'language', type: 'type', source: 'source'
      }
    end

    let(:premium_tuples)   { {age: 12, cost: 227.07} }
    let(:effective_period) { effective_date.beginning_of_year..(effective_date.end_of_year) }
    let(:premium_tables)   { [{effective_period: effective_period, premium_tuples: [premium_tuples], rating_area_id: BSON::ObjectId.new}] }

    let(:product) do
      {
        benefit_market_kind: :benefit_market_kind, application_period: application_period, kind: :kind,
        hbx_id: 'hbx_id', title: 'title', description: 'description', product_package_kinds: [:product_package_kinds],
        issuer_profile_id: BSON::ObjectId.new, premium_ages: 18..60, provider_directory_url: 'provider_directory_url',
        is_reference_plan_eligible: true, deductible: 'deductible', family_deductible: 'family_deductible',
        issuer_assigned_id: 'issuer_assigned_id', service_area_id: BSON::ObjectId.new, network_information: 'network_information',
        nationwide: true, dc_in_network: false, sbc_document: sbc_document, premium_tables: premium_tables
      }
    end

    let(:products)                      { [product] }
    let(:required_params) do
      missing_params.merge({contribution_model: contribution_model, contribution_models: contribution_models,
                            pricing_model: pricing_model, products: products})
    end

    context "with a required only" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end

    context "with all params" do
      let(:all_params) { required_params.merge({description: description, assigned_contribution_model: assigned_contribution_model})}

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end