# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayPerStayService do
  let(:subject) { Products::Services::CopayPerStayService.new(service_visit) }
  let(:amount) { "$300.00" }
  let(:not_applicable) {"Not Applicable"}
  let(:zero) { "$0.00" }
  let(:percentage) {"100%"}
  let(:service_visit) { build(:products_qhp_service_visit) }

  context "In Network Costs" do
    context "$[PARAM] Copay per Stay/Not Applicable Coinsurance" do

      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} Copay per Stay"
        service_visit.co_insurance_in_network_tier_1 = not_applicable
        expect(subject.in_network_process).to eq "#{amount} copay per stay"
      end
    end

    context "$[PARAM] Copay per Stay after deductible/100% Coinsurance" do

      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} Copay per Stay after deductible"
        service_visit.co_insurance_in_network_tier_1 = percentage
        expect(subject.in_network_process).to eq "You must meet the deductible first, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay after deductible/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} Copay per Stay after deductible"
        service_visit.co_insurance_in_network_tier_1 = not_applicable
        expect(subject.in_network_process).to eq "You must meet the deductible first, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay with deductible/Not Applicable Coinsurance" do
      let(:result) {"You pay #{amount} copay per stay. You are also responsible for any remaining allowed charges, which will accrue towards your yearly deductible."}

      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} Copay per Stay with deductible"
        service_visit.co_insurance_in_network_tier_1 = not_applicable
        expect(subject.in_network_process).to eq result
      end
    end

    context "$0 Copay per stay/100% Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = zero
        service_visit.co_insurance_in_network_tier_1 = percentage
        expect(subject.in_network_process).to eq "Not covered. You are responsible for the full cost."
      end
    end
  end

  context "Out of Network Costs" do
    context "$[PARAM] Copay per Stay after deductible/100% Coinsurance" do

      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} Copay per Stay after deductible"
        service_visit.co_insurance_out_of_network = percentage
        expect(subject.out_network_process).to eq "You must first meet the out-of-network deductible, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay after deductible/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} Copay per Stay after deductible"
        service_visit.co_insurance_out_of_network = not_applicable
        expect(subject.out_network_process).to eq "You must first meet the out-of-network deductible, then #{amount} per stay."
      end
    end

    context "$[PARAM] Copay per Stay with deductible/Not Applicable Coinsurance" do
      let(:result) {"You pay #{amount} copay per stay. You are also responsible for any remaining allowed charges, which will accrue towards your yearly out-of-network deductible."}

      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} Copay per Stay with deductible"
        service_visit.co_insurance_out_of_network = not_applicable
        expect(subject.out_network_process).to eq result
      end
    end

    context "$0 Copay per stay/100% Coinsurance" do
      it "should return translated result" do
        service_visit.copay_out_of_network = zero
        service_visit.co_insurance_out_of_network = percentage
        expect(subject.out_network_process).to eq "Not covered. You are responsible for the full cost."
      end
    end
  end
end
