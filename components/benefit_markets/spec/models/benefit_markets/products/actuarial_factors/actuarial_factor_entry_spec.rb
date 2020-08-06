# frozen_string_literal: true

require "rails_helper"

module BenefitMarkets
  RSpec.describe Products::ActuarialFactors::ActuarialFactorEntry do
    let(:validation_errors) do
      subject.valid?
      subject.errors
    end

    it "requires a factor key" do
      expect(validation_errors.key?(:factor_key)).to be_truthy
    end

    it "requires a factor value" do
      expect(validation_errors.key?(:factor_value)).to be_truthy
    end
  end
end
