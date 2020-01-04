# frozen_string_literal: true

require 'spec_helper'

module BenefitSponsors
  RSpec.describe Serializers::ProductSummarySerializer do
    describe '.serialized_json', dbclean: :after_each do
      let(:subject) { Serializers::ProductSummarySerializer.new(plan_details).serialized_json }
      let(:plan_details) { build(:products_qhp_service_visit, copay_in_network_tier_1: "$300.00 copay after deductible", copay_out_of_network: "$0.00 Copay per Day", visit_type: "Separate Drug Deductible") }
      let(:serializable_hash) {JSON.parse(subject)}

      it "serialized output has correct attributes and values" do
        expect(serializable_hash['data']["attributes"].value?(plan_details.visit_type)).to be_truthy
        expect(serializable_hash['data']["attributes"].value?(plan_details.copay_in_network_tier_1)).to be_truthy
        expect(serializable_hash['data']["attributes"].value?(plan_details.copay_out_of_network)).to be_truthy
        expect(serializable_hash['data']["attributes"].value?("Prescription Drugs")).to be_truthy
      end
    end

  end
end
