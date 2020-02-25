# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Locations::RatingAreaContract do

  let(:active_year)              { TimeKeeper.date_of_record.year }
  let(:exchange_provided_code)   { 'code' }
  let(:county_zip_ids)           { [{}] }
  let(:covered_states)           { [{}] }

  let(:missing_params)      { {county_zip_ids: county_zip_ids, exchange_provided_code: exchange_provided_code} }
  let(:invalid_params)      { missing_params.merge({active_year: 'year', covered_states: {}}) }
  let(:error_message1)      { {:covered_states => ["is missing"], :active_year => ["is missing"]} }
  let(:error_message2)      { {:active_year => ["must be an integer"], :covered_states => ["must be an array"]} }

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
      let(:required_params)     { missing_params.merge({active_year: active_year, covered_states: covered_states}) }

      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end