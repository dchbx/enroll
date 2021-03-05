# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::SponsoredBenefits::ContributionLevelContract do

  let(:display_name)             { 'Employee Only' }
  let(:contribution_unit_id)     { BSON::ObjectId.new }
  let(:is_offered)               { true }
  let(:contribution_factor)      { 0.75 }
  let(:min_contribution_factor)  { 0.5 }
  let(:contribution_cap)         { '0.75' }
  let(:flat_contribution_amount) { '227.07' }  #TODO: fix this

  let(:missing_params)   { {display_name: display_name, contribution_unit_id: contribution_unit_id, is_offered: is_offered, contribution_factor: contribution_factor, contribution_cap: contribution_cap} }
  let(:invalid_params)   { missing_params.merge({min_contribution_factor: 'one', flat_contribution_amount: '222' })}
  let(:error_message1)   { {:min_contribution_factor => ["is missing"], :flat_contribution_amount => ["is missing"], :order => ["is missing"]} }
  let(:error_message2)   { {:min_contribution_factor => ["must be a float"], :order => ["is missing"]} }

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
    context "with all/required params" do
      let(:all_params) { missing_params.merge({min_contribution_factor: min_contribution_factor, flat_contribution_amount: flat_contribution_amount, order: 1 }) }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end
