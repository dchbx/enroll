require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignOrganization, type: :model, dbclean: :around_each do

    describe "#expire proposals for non Prospect Employer" do
      let!(:organization) { create(:plan_design_organization,
                              sponsor_profile_id: "1234",
                              owner_profile_id: "5678",
                              legal_name: "ABC Company",
                              sic_code: "0345" ) }

      context "when in an expirable state" do
        before(:each) do
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "draft"})
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "draft"})
          organization.expire_proposals
        end

        it "should change the status to expired" do
          expect(organization.plan_design_proposals[0].aasm_state).to eq "expired"
          expect(organization.plan_design_proposals[1].aasm_state).to eq "expired"
        end
      end

      context "when in NON expirable states" do
        before(:each) do
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "published"})
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "claimed"})
          organization.expire_proposals
        end

        it "should have published as the new aasm state" do
          expect(organization.plan_design_proposals[0].aasm_state).to_not eq "expired"
          expect(organization.plan_design_proposals[1].aasm_state).to_not eq "expired"
        end
      end
    end

    describe "#expire proposals for Prospect" do
      let!(:organization) { create(:plan_design_organization,
                        sponsor_profile_id: nil,
                        owner_profile_id: "5678",
                        legal_name: "ABC Company",
                        sic_code: "0345" ) }

      context "when in an expirable state" do
        before(:each) do
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "draft"})
        end

        it "should NOT change the status to expired" do
          expect(organization.plan_design_proposals[0].can_be_expired?).to eq false
        end
      end
    end


    describe "Organization with customer" do 
      
      let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month}
      let(:plan_year) { double(start_on: start_on)}
      let(:census_employees) { double(non_terminated: [])}
      let(:employer_profile) { double(active_plan_year: plan_year, census_employees: census_employees, sic_code: "0345")}
 
      let!(:plan_design_organization) { create(:plan_design_organization, 
        owner_profile_id: "5678",
        legal_name: "ABC Company",
        sic_code: "0345" ) 
      }

      let(:calculated_dates) { SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates }

      before do 
        allow(plan_design_organization).to receive(:employer_profile).and_return(employer_profile)
      end

      describe ".calculate_start_on_dates" do
        context "active plan year present" do
          it "should return only renewal plan year begin date" do
            expect(plan_design_organization.calculate_start_on_dates).to eq [start_on.next_year]
          end
        end

        context "no active plan year present" do
          let(:plan_year) { nil }

          it "should return calculated start dates" do
            expect(plan_design_organization.calculate_start_on_dates).to eq calculated_dates
          end
        end
      end

      describe ".new_proposal_state" do
        context "active plan year present" do
          it "should return renewal status" do
            expect(plan_design_organization.new_proposal_state).to eq 'renewing_draft'
          end
        end

        context "no active plan year present" do
          let(:plan_year) { nil }

          it "should return draft status" do
            expect(plan_design_organization.new_proposal_state).to eq 'draft'
          end
        end
      end

      describe ".build_proposal_from_existing_employer_profile" do

        before do
          allow_any_instance_of(SponsoredBenefits::BenefitApplications::PlanDesignProposalBuilder).to receive(:has_access?).and_return(true)
        end

        context "active plan year present" do
          it "should return plan design proposal with renewal effective date and status" do
            proposal = plan_design_organization.build_proposal_from_existing_employer_profile
            expect(proposal).to be_kind_of(SponsoredBenefits::Organizations::PlanDesignProposal)
            expect(proposal.effective_date).to eq start_on.next_year
            expect(proposal.aasm_state).to eq 'renewing_draft'
          end
        end

        context "no active plan year present" do
          let(:plan_year) { nil }

          it "should return plan design proposal with initial effective date and status" do
            proposal = plan_design_organization.build_proposal_from_existing_employer_profile
            expect(proposal).to be_kind_of(SponsoredBenefits::Organizations::PlanDesignProposal)
            expect(proposal.effective_date).to eq calculated_dates[0]
            expect(proposal.aasm_state).to eq 'draft'
          end
        end
      end
    end
  end
end
