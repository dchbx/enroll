# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Locations::ServiceAreaContract do

  let(:id)                      { BSON::ObjectId.new }
  let(:active_year)             { TimeKeeper.date_of_record.year }
  let(:issuer_provided_title)   { 'Issuer Provided Title' }
  let(:issuer_provided_code)    { 'Issuer Provided Code' }
  let(:issuer_profile_id)       { BSON::ObjectId.new }
  let(:issuer_hios_id)          { :hios_id }
  let(:county_zip_ids)          { [{}] }
  let(:covered_states)          { ['DC'] }

  let(:missing_params) do
    {
      _id: id,
      active_year: active_year,
      issuer_provided_title: issuer_provided_title,
      issuer_provided_code: issuer_provided_code,
      county_zip_ids: county_zip_ids,
      covered_states: covered_states
    }
  end

  let(:invalid_params)      { missing_params.merge({issuer_profile_id: issuer_profile_id, issuer_hios_id: :issuer_hios_id}) }
  let(:error_message1)      { {:issuer_profile_id => ["is missing"]} }
  let(:error_message2)      { {:issuer_hios_id => ["must be a string"]} }

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
      let(:required_params)     { missing_params.merge({issuer_profile_id: BSON::ObjectId.new, issuer_hios_id: issuer_hios_id.to_s}) }

      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end