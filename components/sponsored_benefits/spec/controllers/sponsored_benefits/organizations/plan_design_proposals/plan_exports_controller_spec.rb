require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::PlanExportsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up broker agency profile for BQT, by using configuration settings"

    let!(:person) { FactoryBot.create(:person, :with_broker_role).tap do |person|
                    person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
    end
    }
    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person ) }
    let(:enrollment_period) {TimeKeeper.date_of_record.beginning_of_month..(TimeKeeper.date_of_record.beginning_of_month + 15.days)}

    describe "POST create" do
      before do
        allow_any_instance_of(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:is_renewing_employer?).and_return(false)
        plan_design_census_employee
        benefit_application.benefit_sponsorship.update_attributes(initial_enrollment_period: enrollment_period)
        sign_in user_with_broker_role
        post :create, params: {plan_design_proposal_id: plan_design_proposal.id, benefit_group: {kind: :health}}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should set the plan_design_organization instance variable" do
        expect(assigns(:plan_design_organization)).to eq plan_design_organization
      end

      it "should set census_employees instance variable" do
        expect(assigns(:census_employees)).to eq(plan_design_proposal.profile.benefit_sponsorships.first.census_employees)
      end
    end
  end
end
