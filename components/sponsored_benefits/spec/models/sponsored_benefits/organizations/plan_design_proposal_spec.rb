require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposal, type: :model do
    let(:initial_enrollment_period){ Date.new(2018,5,1)..Date.new(2019,4,30) }
    let(:profile) { SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new }

    describe "#instance methods" do
      let(:organization){ SponsoredBenefits::Organizations::PlanDesignOrganization.new }
      let(:plan_design_proposals){
        [organization.plan_design_proposals.build({title: "new proposal for new client", profile: profile})]
      }
      let(:plan_design_proposal){ plan_design_proposals[0] }

      context "when instantiated" do
        it "should return true when all data elements are valid" do
          expect(plan_design_proposal.can_quote_be_published?).to eq true
        end

        it "should have draft as the initial state" do
          expect(plan_design_proposal.aasm_state).to eq "draft"
        end

        it "should have no claim code and published_on date" do
          expect(plan_design_proposal.claim_code).to eq nil
          expect(plan_design_proposal.published_on).to eq nil
        end
      end

      context "when published" do
        before(:each) do
          plan_design_proposal.publish!
        end

        it "should have published as the new aasm state" do
          expect(plan_design_proposal.aasm_state).to eq "published"
        end

        it "should have a claim code and published_on date" do
          expect(plan_design_proposal.claim_code).not_to eq nil
          expect(plan_design_proposal.published_on).not_to eq nil
          expect(plan_design_proposal.published_on).to eq TimeKeeper.date_of_record
        end
      end

    end
  end
end
