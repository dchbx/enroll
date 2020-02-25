# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Locations::CountyZipContract do

  let(:county_name)   { "County" }
  let(:zip)           { "Zip" }
  let(:state)         { "State" }

  let(:missing_params)      { {county_name: county_name, zip: zip} }
  let(:invalid_params)      { missing_params.merge({state: ''}) }
  let(:error_message1)      { {:state => ["is missing"]} }
  let(:error_message2)      { {:state => ["must be filled"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do
    context "with all params" do
      let(:required_params)     { missing_params.merge({state: state}) }

      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end