require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

class AcaHelperModStubber
  extend ::Config::AcaHelper
end

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::BenefitGroupsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up broker agency profile for BQT, by using configuration settings"

    let!(:person) { FactoryBot.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person ) }

    let(:attrs) {
      {
        reference_plan_id: health_reference_plan.id,
        plan_option_kind: "single_carrier",
        kind: "health",
        relationship_benefits_attributes: relationship_attrs
      }
    }

    let(:relationship_attrs) {
      {
        "0" =>{"relationship"=>"employee", "premium_pct"=>"86", "offered"=>"true"},
        "1" =>{"relationship"=>"spouse", "premium_pct"=>"73", "offered"=>"true"},
        "2" =>{"relationship"=>"domestic_partner", "premium_pct"=>"69", "offered"=>"true"},
        "3" =>{"relationship"=>"child_under_26", "premium_pct"=>"67", "offered"=>"true"},
        "4" =>{"relationship"=>"child_26_and_over", "premium_pct"=>"0", "offered"=>"false"}
      }
    }

    # To avoid the dependency of adding benefit markets dummy
    before :each do
      allow_any_instance_of(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:is_renewing_employer?).and_return(false)
    end

    describe "POST #create" do
      before do
        benefit_application.benefit_groups.delete_all
        sign_in user_with_broker_role
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        post :create, params: {plan_design_proposal_id: plan_design_proposal.id, benefit_group: attrs}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should render json" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['url']).to eq("/sponsored_benefits/organizations/plan_design_proposals/#{plan_design_proposal.id}/plan_reviews/new")
      end
    end

    describe "POST #create - flexible rules" do

      let(:relationship_attrs) do
        {
          "0" => {"relationship" => "employee", "premium_pct" => "0", "offered" => "true"},
          "1" => {"relationship" => "spouse", "premium_pct" => "0", "offered" => "true"},
          "2" => {"relationship" => "domestic_partner", "premium_pct" => "0", "offered" => "true"},
          "3" => {"relationship" => "child_under_26", "premium_pct" => "0", "offered" => "true"},
          "4" => {"relationship" => "child_26_and_over", "premium_pct" => "0", "offered" => "false"}
        }
      end

      let(:flexible_rules_enabled) { AcaHelperModStubber.flexible_contribution_model_enabled_for_bqt_for_initial_period.cover?(benefit_application.effective_period.min.to_date) }

      before do
        benefit_application.benefit_groups.delete_all
        sign_in user_with_broker_role
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        post :create, params: {plan_design_proposal_id: plan_design_proposal.id, benefit_group: attrs}
      end

      it "should be success when employee contribution is less than 50 percent" do
        expect(response).to have_http_status(:success) if flexible_rules_enabled
      end

      it "should render json when employee contribution is less than 50 percent" do
        if flexible_rules_enabled
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['url']).to eq("/sponsored_benefits/organizations/plan_design_proposals/#{plan_design_proposal.id}/plan_reviews/new")
        end
      end
    end

    describe "DELETE #destroy" do
      before do
        sign_in user_with_broker_role
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        delete :destroy, params: {plan_design_proposal_id: plan_design_proposal.id, id: benefit_group.id, benefit_group: {kind: 'dental'}}
      end

      it "redirects to new_organizations_plan_design_proposal_plan_selection_path" do
        expect(response).to redirect_to(new_organizations_plan_design_proposal_plan_selection_path)
      end
    end
  end
end
