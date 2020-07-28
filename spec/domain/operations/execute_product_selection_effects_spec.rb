# frozen_string_literal: true

require "rails_helper"

describe Operations::ExecuteProductSelectionEffects, "invoked with:
- an HbxEnrollment
- a selected Product
- a Family
" do
  let(:family) { instance_double(Family) }
  let(:selected_product) do
    instance_double(
      BenefitMarkets::Products::Product
    )
  end
  let(:enrollment) { instance_double(HbxEnrollment) }

  let(:operation_options) do
    Entities::ProductSelection.new(
      {
        enrollment: enrollment,
        product: selected_product,
        family: family
      }
    )
  end

  let(:success) do
    double(success?: true)
  end

  let(:settings) { double }
  let(:operation_setting) { double }

  before :each do
    allow(settings).to receive(:settings).with(:operation).and_return(operation_setting)
    allow(operation_setting).to receive(:item).and_return(setting_value)
  end

  let(:result) do
    Operations::ExecuteProductSelectionEffects.call(operation_options)
  end

  describe "with no operation set" do

    before :each do
      allow(EnrollRegistry).to receive(:[]).with(:product_selection_effects).and_raise(
        ResourceRegistry::Error::FeatureNotFoundError.new("you didn't set this up")
      )
    end

    let(:setting_value) do
      "::Operations::ProductSelectionEffects::DefaultProductSelectionEffects"
    end

    it "is a failure" do
      expect(result.success?).to be_falsey
    end

    it "fails for the right reason" do
      expect(result.failure).to eq :product_selection_effect_operation_unspecified
    end
  end

  describe "with an invalid operation set" do

    before :each do
      allow(EnrollRegistry).to receive(:[]).with(:product_selection_effects).and_return(settings)
      allow(
        ::Operations::ProductSelectionEffects::DchbxProductSelectionEffects
      ).to receive(:call).with(operation_options).and_return(success)
    end

    let(:setting_value) do
      "TotallyBogusClassDontPretend"
    end

    it "is a failure" do
      expect(result.failure?).to be_truthy
    end

    it "fails for the right reason" do
      expect(result.failure).to eq :product_selection_effect_operation_no_such_class
    end
  end

  describe "set to use the default operation" do

    before :each do
      allow(EnrollRegistry).to receive(:[]).with(:product_selection_effects).and_return(settings)
      allow(
        ::Operations::ProductSelectionEffects::DefaultProductSelectionEffects
      ).to receive(:call).with(operation_options).and_return(success)
    end

    let(:setting_value) do
      "::Operations::ProductSelectionEffects::DefaultProductSelectionEffects"
    end

    it "is successful" do
      expect(result.success?).to be_truthy
    end
  end

  describe "set to use the DCHBX operation" do

    before :each do
      allow(EnrollRegistry).to receive(:[]).with(:product_selection_effects).and_return(settings)
      allow(
        ::Operations::ProductSelectionEffects::DchbxProductSelectionEffects
      ).to receive(:call).with(operation_options).and_return(success)
    end

    let(:setting_value) do
      "::Operations::ProductSelectionEffects::DchbxProductSelectionEffects"
    end

    it "is successful" do
      expect(result.success?).to be_truthy
    end
  end
end