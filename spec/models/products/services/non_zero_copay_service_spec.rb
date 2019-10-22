# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::NonZeroCopayService do
  let(:not_applicable) {"Not Applicable"}

  context "In Network Costs" do
    context "$[PARAM] Copay/Not Applicable Coinsurance" do
      let(:number) {"$20"}
      let(:service_visit_drug_cost) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: number, co_insurance_in_network_tier_1: not_applicable, visit_type: "Separate Drug Deductible")
      end

      let(:service_visit_medical_cost) do
        build(:products_qhp_service_visit, copay_in_network_tier_1: number, co_insurance_in_network_tier_1: not_applicable, visit_type: "Dental Check-Up for Children")
      end

      it "should return translated result viewing Drug Costs" do
        expect(Products::Services::NonZeroCopayService.new(service_visit_drug_cost).in_network_process).to eq "#{number} per prescription"
      end

      it "should return translated result viewing Medical Costs" do
        expect(Products::Services::NonZeroCopayService.new(service_visit_medical_cost).in_network_process).to eq "#{number} per visit"
      end
    end
  end
end
