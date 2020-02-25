# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::PricingModels::PricingModelContract do

  let(:name1)                     { 'name' }
  let(:price_calculator_kind)    { 'price_calculator_kindr' }
  let(:product_multiplicities)   { [:product_multiplicities]}
  let(:pricing_units)            { [{name: 'name', display_name: 'Employee Only', order: 1}] }
  let(:member_relationships)     { [{relationship_name: :employee, relationship_kinds: ['self'], age_threshold: 18, age_comparison: :==, disability_qualifier: true  }] }

  let(:missing_params)   { {name: name1, price_calculator_kind: price_calculator_kind, pricing_units: pricing_units} }
  let(:required_params)  { missing_params.merge({product_multiplicities: product_multiplicities, member_relationships: member_relationships}) }
  let(:invalid_params)   { missing_params.merge({product_multiplicities: [{}], member_relationships: [:member_relationships]}) }
  let(:error_message1)   { {:product_multiplicities => ["is missing"], :member_relationships => ["is missing"]} }
  let(:error_message2)   { {:member_relationships => {0 => ["must be a hash"]}, :product_multiplicities => {0 => ["must be Symbol"]}} }

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

    context "with all/required only" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end
