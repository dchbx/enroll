# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationForms::CoverageRecordFormContract do

  let(:missing_params)   { {gender: 'male', address: {}, email: {}} }
  let(:error_message)    { {:is_applying_coverage => ["is missing"]} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({is_applying_coverage: false})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
