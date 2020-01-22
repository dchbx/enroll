require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe SponsoredBenefits::Organizations::PlanDesignProposalsController, type: :controller, dbclean: :around_each do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up broker agency profile for BQT, by using configuration settings"
    let(:broker_double) { double(id: '12345') }
    let(:current_person) { double(:current_person) }
    let(:broker_role) { double(:broker_role, broker_agency_profile_id: '5ac4cb58be0a6c3ef400009b') }
    let(:datatable) { double(:datatable) }
    let(:sponsor) { double(:sponsor, id: '5ac4cb58be0a6c3ef400009a', sic_code: '1111') }
    let(:active_user) { double(:has_hbx_staff_role? => false) }
    let(:open_enrollment_start_on) { (beginning_of_next_month - 15.days).prev_month }
    let(:beginning_of_next_month) { Date.today.next_month.beginning_of_month }
    let(:end_of_month) { Date.today.end_of_month }
    let(:initial_enrollment_period) { (beginning_of_next_month..(beginning_of_next_month + 1.year - 1.day)) }

    let(:valid_attributes) {
      {
        title: 'A Proposal Title',
        effective_date: beginning_of_next_month.strftime("%Y-%m-%d"),
        profile: {
          benefit_sponsorship: {
            initial_enrollment_period: initial_enrollment_period,
            annual_enrollment_period_begin_month_of_year: beginning_of_next_month.month,
            benefit_application: {
              effective_period: initial_enrollment_period,
              open_enrollment_period: (Date.today..end_of_month)
            }
          }
        }
      }
    }


    let(:invalid_attributes) {
      {
        title: 'A Proposal Title',
        effective_date: beginning_of_next_month.strftime("%Y-%m-%d"),
        profile: {
          benefit_sponsorship: {
            initial_enrollment_period: nil,
            annual_enrollment_period_begin_month_of_year: beginning_of_next_month.month,
            benefit_application: {
              effective_period: ((end_of_month + 1.year)..beginning_of_next_month),
              open_enrollment_period: (beginning_of_next_month.end_of_month..beginning_of_next_month)
            }
          }
        }
      }
    }

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # BenefitApplications::BenefitApplicationsController. Be sure to keep this updated too.
    let(:valid_session) { {} }

    before do
      benefit_application
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(subject).to receive(:active_user).and_return(active_user)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      allow(broker_role).to receive(:broker_agency_profile_id).and_return(plan_design_organization.owner_profile_id)
      allow(subject).to receive(:effective_datatable).and_return(datatable)
      allow(subject).to receive(:employee_datatable).and_return(datatable)
      allow(broker_role).to receive(:benefit_sponsors_broker_agency_profile_id).and_return(plan_design_organization.owner_profile_id)
      allow(controller).to receive(:set_broker_agency_profile_from_user).and_return(plan_design_organization.broker_agency_profile)
    end

    describe "GET #index" do
      it "returns a success response" do
        get :index, params: { plan_design_organization_id: plan_design_organization.id, profile_id:  plan_design_organization.owner_profile_id}
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns a success response" do
        get :show, params: { id: plan_design_proposal.to_param }
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new, params: { plan_design_organization_id: plan_design_organization.id, profile_id:  plan_design_organization.owner_profile_id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        get :edit, params: { id: plan_design_proposal.to_param, plan_design_organization_id: plan_design_organization.id, profile_id:  plan_design_organization.owner_profile_id }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Organizations::PlanDesignProposal" do
          expect {
            post :create, xhr: true, params: { plan_design_organization_id: plan_design_organization.to_param, forms_plan_design_proposal: valid_attributes }
          }.to change { plan_design_organization.reload.plan_design_proposals.count }.by(1)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, xhr: true, params: { plan_design_organization_id: plan_design_organization.to_param, forms_plan_design_proposal: invalid_attributes}
          expect(response).to be_successful
        end
      end
    end

    # describe "PUT #update" do
    #   context "with valid params" do
    #     let(:new_attributes) {
    #       skip("Add a hash of attributes valid for your model")
    #     }

    #     it "updates the requested organizations_plan_design_proposal" do
    #       plan_design_proposal = Organizations::PlanDesignProposal.create! valid_attributes
    #       put :update, {:id => plan_design_proposal.to_param, :organizations_plan_design_proposal => new_attributes}, valid_session
    #       plan_design_proposal.reload
    #       skip("Add assertions for updated state")
    #     end

    #     it "redirects to the organizations_plan_design_proposal" do
    #       plan_design_proposal = Organizations::PlanDesignProposal.create! valid_attributes
    #       put :update, {:id => plan_design_proposal.to_param, :organizations_plan_design_proposal => valid_attributes}, valid_session
    #       expect(response).to redirect_to(plan_design_proposal)
    #     end
    #   end

    #   context "with invalid params" do
    #     it "returns a success response (i.e. to display the 'edit' template)" do
    #       plan_design_proposal = Organizations::PlanDesignProposal.create! valid_attributes
    #       put :update, {:id => plan_design_proposal.to_param, :organizations_plan_design_proposal => invalid_attributes}, valid_session
    #       expect(response).to be_successful
    #     end
    #   end
    # end

    # describe "DELETE #destroy" do
    #   it "destroys the requested organizations_plan_design_proposal" do
    #     plan_design_proposal = Organizations::PlanDesignProposal.create! valid_attributes
    #     expect {
    #       delete :destroy, {:id => plan_design_proposal.to_param}, valid_session
    #     }.to change(Organizations::PlanDesignProposal, :count).by(-1)
    #   end

    #   it "redirects to the organizations_plan_design_proposals list" do
    #     plan_design_proposal = Organizations::PlanDesignProposal.create! valid_attributes
    #     delete :destroy, {:id => plan_design_proposal.to_param}, valid_session
    #     expect(response).to redirect_to(organizations_plan_design_proposals_url)
    #   end
    # end

  end
end
