# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::ZeroCopayService do
  let(:subject) { Products::Services::ZeroCopayService.new(service_visit) }
  let(:zero_dollar) { "$0.00" }
  let(:no_charge) {"No Charge"}
  let(:service_visit) { build(:products_qhp_service_visit) }

  context "In Network Costs" do
    context "zero copay and zero coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = zero_dollar
        service_visit.co_insurance_in_network_tier_1 = zero_dollar
        expect(subject.in_network_process).to eq no_charge
      end
    end

    context "zero copay and No Charge Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = zero_dollar
        service_visit.co_insurance_in_network_tier_1 = no_charge
        expect(subject.in_network_process).to eq no_charge
      end
    end

    context "zero copay and [PARAM]% Coinsurance after deductible" do
      let(:percentage) {"20%"}

      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = zero_dollar
        service_visit.co_insurance_in_network_tier_1 = "#{percentage} Coinsurance after deductible"
        service_visit.visit_type = "Dental Check-Up for Children"
        expect(subject.in_network_process).to eq "You must meet the deductible first, then #{percentage} of allowed charges"
      end
    end

    context "zero copay and 100% coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = zero_dollar
        service_visit.co_insurance_in_network_tier_1 = "100%"
        expect(subject.in_network_process).to eq "Not covered. You are responsible for the full cost"
      end
    end
  end


  context "Out of Network Costs" do
    context "zero copay and [PARAM]% Coinsurance after deductible" do
      let(:percentage) {"20%"}

      it "should return translated result" do
        service_visit.copay_out_of_network = zero_dollar
        service_visit.co_insurance_out_of_network = "#{percentage} Coinsurance after deductible"
        service_visit.visit_type = "Durable Medical Equipment"
        expect(subject.out_network_process).to eq "You must meet the out-of-network deductible first, then #{percentage} of allowed charges per device."
      end
    end
  end
end
