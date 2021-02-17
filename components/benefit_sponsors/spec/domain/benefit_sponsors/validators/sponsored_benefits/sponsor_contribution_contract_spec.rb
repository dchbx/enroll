# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::SponsoredBenefits::SponsorContributionContract do

  let(:contribution_level) do
    {
      display_name: 'Employee Only', order: 1, contribution_unit_id: BSON::ObjectId.new,
      is_offered: true, contribution_factor: 0.75, min_contribution_factor: 0.5,
      contribution_cap: '0.75', flat_contribution_amount: '227.07' #TODO: Fix this
    }
  end

  let(:contribution_levels)  { [contribution_level] }

  let(:missing_params)       { {} }
  let(:invalid_params)       { {contribution_levels: {}} }
  let(:error_message1)       { {:contribution_levels => ["is missing"]} }
  let(:error_message2)       { {:contribution_levels => ["must be an array"]} }

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
      let(:all_params) { {contribution_levels: contribution_levels} }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end
