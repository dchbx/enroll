require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe SponsoredBenefits::Organizations::PlanDesignProposals::PlanReviewsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up broker agency profile for BQT, by using configuration settings"

    let!(:person) { FactoryBot.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person ) }

    before do
      allow_any_instance_of(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:is_renewing_employer?).and_return(false)
      plan_design_census_employee
      benefit_application
      person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
      sign_in user_with_broker_role
    end
 
    describe "GET #new" do
      before do
        get :new, params: {plan_design_proposal_id: plan_design_proposal.id}
      end

      it "should return a success response" do
        expect(response).to have_http_status(:success)
      end

      it "should set the plan_design_organization instance variable" do
        expect(assigns(:plan_design_organization)).to eq plan_design_proposal.plan_design_organization
      end

      it "should set benefit_group instance variable" do
        expect(assigns(:benefit_group)).to eq benefit_group
      end

      it "should set census_employees instance variable" do
        expect(assigns(:census_employees)).to eq(plan_design_proposal.profile.benefit_sponsorships.first.census_employees)
      end
    end

    describe "GET #show" do
      before do
        get :show, params: {plan_design_proposal_id: plan_design_proposal.id}
      end

      it "should return a success response" do
        expect(response).to have_http_status(:success)
      end

      it "should set the plan_design_organization instance variable" do
        expect(assigns(:plan_design_organization)).to eq plan_design_proposal.plan_design_organization
      end

      it "should set the benefit_group instance variable" do
        expect(assigns(:benefit_group)).to eq benefit_group
      end

      it "should set the census_employees instance variable" do
        expect(assigns(:census_employees)).to eq(plan_design_proposal.profile.benefit_sponsorships.first.census_employees)
      end
    end
  end
end
