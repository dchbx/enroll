# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::PricingUnits::Create, dbclean: :after_each do

  let(:ee_pricing_unit) do
    {
      "_id"=>BSON::ObjectId.new,
      "created_at"=>nil,
      "discounted_above_threshold"=>nil,
      "display_name"=>"Employee",
      "eligible_for_threshold_discount"=>false,
      "name"=>"employee",
      "order"=>0,
      "updated_at"=>nil
    }
  end

  context 'sending required parameters for pricing unit' do

    [:single_product, :single_issuer, :metal_level, :multi_product].each do |package_kind|

      let(:params)                      { {pricing_unit_params: ee_pricing_unit, package_kind: package_kind} }

      it "should be successful for #{package_kind} package_kind" do
        expect(subject.call(params).success?).to be_truthy
      end

      it "should create appropriate pricing unit entity for #{package_kind} package_kind" do
        if package_kind == :single_product && Settings.site.key == :cca
          expect(subject.call(params).success).to be_a BenefitMarkets::Entities::TieredPricingUnit
        else
          expect(subject.call(params).success).to be_a BenefitMarkets::Entities::RelationshipPricingUnit
        end
      end
    end
  end
end