# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayAfterDeductibleService do
  let(:subject) { Products::Services::CopayWithDeductibleService.new(service_visit) }
  let(:amount) { "$75" }
  let(:percentage) {"100%"}
  let(:qhp_cost_share_variance) { build(:products_qhp_cost_share_variance, :qhp_service_visits => [service_visit]) }
  let(:service_visit) { build(:products_qhp_service_visit) }

  before do
    allow(service_visit).to receive(:qhp_cost_share_variance).and_return(qhp_cost_share_variance)
  end

  context "In Network Costs" do
    context "$[PARAM] Copay after deductible/No Charge after deductible Coinsurance" do
      context "with no out-of-network deductible" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_in_network_deductible?).and_return true
        end

        it "should return translated result with excepted services" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Emergency Room Services"
          expect(subject.in_network_process).to eq "You must pay #{amount} per visit."
        end

        it "should return translated result with devices" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.in_network_process).to eq "You must pay #{amount} per device."
        end
      end

      context "with no out-of-network deductible" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_in_network_deductible?).and_return false
        end

        it "should return translated result with devices" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.in_network_process).to eq "You must first pay #{amount} per device. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
        end

        it "should return translated result with remaining services" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          expect(subject.in_network_process).to eq "You must first pay #{amount} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge"
        end
      end
    end

    context "$[PARAM] Copay with deductible/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} copay with deductible"
        service_visit.co_insurance_in_network_tier_1 = "Not Applicable"
        expect(subject.in_network_process).to eq "You must first pay #{amount} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. Then, no charge."
      end
    end
  end

  context "Out of Network Costs" do
    context "$[PARAM] Copay after deductible/No Charge after deductible Coinsurance" do
      context "with no out-of-network deductible" do

        before do
          allow(qhp_cost_share_variance).to receive(:no_out_of_network_deductible?).and_return true
        end

        it "should return translated result for excepted services" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          service_visit.visit_type = "Emergency Room Services"
          expect(subject.out_network_process).to eq "You must first pay #{amount} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
        end

        it "should return translated result for devices" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.out_network_process).to eq "You must first pay #{amount} per device. Then, pay all of the remaining allowed charges, until you meet the deductible. After you meet the deductible, no charge."
        end
      end

      context "with no out-of-network deductible" do
        before do
          allow(qhp_cost_share_variance).to receive(:no_out_of_network_deductible?).and_return false
        end

        it "should return translated result with devices" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.out_network_process).to eq "You must first pay #{amount} per device. Then, pay all of the remaining allowed charges, until you meet the out-of-network deductible. After you meet the deductible, no charge."
        end

        it "should return translated result with remaining services" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          expect(subject.out_network_process).to eq "You must first pay #{amount} per visit. Then, pay all of the remaining allowed charges, until you meet the out-of-network deductible. After you meet the deductible, no charge."
        end
      end
    end

    context "$[PARAM] Copay with deductible/Not Applicable Coinsurance" do
      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} copay with deductible"
        service_visit.co_insurance_out_of_network = "Not Applicable"
        expect(subject.out_network_process).to eq "You must first pay #{amount} per visit. Then, pay all of the remaining allowed charges, until you meet the deductible. Then, no charge."
      end
    end
  end
end
