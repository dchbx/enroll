# frozen_string_literal: true

require 'rails_helper'

describe Products::Services::CopayAfterDeductibleService do
  let(:subject) { Products::Services::CopayAfterDeductibleService.new(service_visit) }
  let(:amount) { "$75" }
  let(:percentage) {"100%"}
  let(:qhp_cost_share_variance) { build(:products_qhp_cost_share_variance, :qhp_service_visits => [service_visit]) }
  let(:service_visit) { build(:products_qhp_service_visit) }

  before do
    allow(service_visit).to receive(:qhp_cost_share_variance).and_return(qhp_cost_share_variance)
  end

  context "In Network Costs" do
    context "$[PARAM] Copay after deductible/100% Coinsurance" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
        service_visit.co_insurance_in_network_tier_1 = percentage
        expect(subject.in_network_process).to eq "You must meet the deductible first, then #{amount} per visit."
      end
    end

    context "$[PARAM] Copay after deductible/No Charge after deductible Coinsurance" do
      context "with Drug costs And Combined Plan (medical and dental deductible)" do
        before do
          allow(qhp_cost_share_variance).to receive(:medical_and_drug_deductible?).and_return true
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          expect(subject.in_network_process).to eq "You must meet the deductible first, then #{amount} per prescription"
        end
      end

      context "with Drug costs And separate drug deductible" do
        before do
          allow(qhp_cost_share_variance).to receive(:separarate_drug_deductible?).and_return true
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "No Charge after deductible"
          service_visit.visit_type = "Separate Drug Deductible"
          expect(subject.in_network_process).to eq "You must meet the separate drug deductible first, then #{amount} per prescription."
        end
      end

      context "for remaining services" do
        before do
          allow(qhp_cost_share_variance).to receive(:separarate_medical_deductible?).and_return true
        end

        it "should return translated result" do
          service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
          service_visit.co_insurance_in_network_tier_1 = "20.00% Coinsurance after deductible"
          expect(subject.in_network_process).to eq "You must meet the deductible first, then #{amount} per visit."
        end
      end
    end

    context "$[PARAM] Copay after deductible/[PARAM]% Coinsurance after deductible" do
      it "should return translated result" do
        service_visit.copay_in_network_tier_1 = "#{amount} copay after deductible"
        service_visit.co_insurance_in_network_tier_1 = "20.00% Coinsurance after deductible"
        expect(subject.in_network_process).to eq "You must meet the deductible first, then #{amount} per visit."
      end
    end
  end


  context "Out of Network Costs" do
    context "$[PARAM] Copay after deductible/100% Coinsurance" do
      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} copay after deductible"
        service_visit.co_insurance_out_of_network = percentage
        expect(subject.out_network_process).to eq "You must meet the out-of-network deductible first, then #{amount} per visit."
      end
    end

    context "$[PARAM] Copay after deductible/[PARAM]% Coinsurance after deductible" do
      it "should return translated result" do
        service_visit.copay_out_of_network = "#{amount} copay after deductible"
        service_visit.co_insurance_out_of_network = "20.00% Coinsurance after deductible"
        expect(subject.out_network_process).to eq "You must meet the out-of-network deductible first, then #{amount} per visit."
      end
    end

    context "$[PARAM] Copay after deductible/No Charge after deductible Coinsurance" do
      context "with no out-of-network deductible" do

        before do
          allow(qhp_cost_share_variance).to receive(:no_out_of_network_deductible?).and_return true
        end

        it "should return translated result for excepted services" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          service_visit.visit_type = "Emergency Room Services"
          expect(subject.out_network_process).to eq "You must meet the deductible first, then #{amount} per visit."
        end

        it "should return translated result for devices" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.out_network_process).to eq "You must meet the deductible first, then #{amount} per device."
        end
      end

      context "with devices" do
        it "should return translated result" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          service_visit.visit_type = "Prosthetic Devices"
          expect(subject.out_network_process).to eq "You must meet the out-of-network deductible first, then #{amount} per device."
        end
      end

      context "for remaining services" do
        it "should return translated result" do
          service_visit.copay_out_of_network = "#{amount} copay after deductible"
          service_visit.co_insurance_out_of_network = "No Charge after deductible"
          expect(subject.out_network_process).to eq "You must meet the out-of-network deductible first, then #{amount} per visit."
        end
      end
    end
  end
end
