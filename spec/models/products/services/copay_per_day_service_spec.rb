# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayPerDayService do
  let(:subject) { Products::Services::CopayPerDayService.new(service_visit) }
  let(:amount) { "$300.00" }
  let(:not_applicable) {"Not Applicable"}
  let(:service_visit) { build(:products_qhp_service_visit) }

  context "In Network Costs" do
    context "$[PARAM] Copay per Day/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} Copay per Day"
        service_visit.co_insurance_in_network_tier_1 = not_applicable
        expect(subject.in_network_process).to eq "#{amount} copay per day"
      end
    end

    context "$0 Copay per day/100% Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "$0.00 Copay per Day"
        service_visit.co_insurance_in_network_tier_1 = "100%"
        expect(subject.in_network_process).to eq "Not covered. You are responsible for the full cost."
      end
    end

    context "$[PARAM] Copay per Day after deductible/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} Copay per Day after deductible"
        service_visit.co_insurance_in_network_tier_1 = not_applicable
        expect(subject.in_network_process).to eq "You must meet the deductible first, then pay #{amount} copay per day."
      end
    end

  end

  context "Out of Network Costs" do
    context "$0 Copay per day/100% Coinsurance" do
      it "should return translated result" do
        service_visit.copay_out_of_network = "$0.00 Copay per Day"
        service_visit.co_insurance_out_of_network = "100%"
        expect(subject.out_network_process).to eq "Not covered. You are responsible for the full cost."
      end
    end

    context "$[PARAM] Copay per Day after deductible/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} Copay per Day after deductible"
        service_visit.co_insurance_out_of_network = not_applicable
        expect(subject.out_network_process).to eq "You must meet the out-of-network deductible first, then pay #{amount} copay per day."
      end
    end
  end
end
