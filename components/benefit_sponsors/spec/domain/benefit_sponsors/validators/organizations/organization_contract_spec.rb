# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationContract do

  let(:missing_params)   { {hbx_id: '1234321',  legal_name: 'abc_organization', entity_kind: :limited_liability_corporation} }
  let(:error_message)    { {:site_id => ["is missing"], :fein => ["is missing"]} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({fein: '987654321', site_id: BSON::ObjectId.new })}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end

    context "with valid all params" do
      let(:all_params) do
        valid_params.merge({home_page: nil, dba: nil})
      end

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end