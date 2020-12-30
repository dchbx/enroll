require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::PlanSelectionsController, type: :controller, dbclean: :around_each  do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    routes { SponsoredBenefits::Engine.routes }

    let!(:person) { FactoryBot.create(:person, :with_broker_role).tap do |person|
                                      person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
    end
    }
    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person ) }
    let(:enrollment_period) {TimeKeeper.date_of_record.beginning_of_month..(TimeKeeper.date_of_record.beginning_of_month + 15.days)}

    describe "GET new" do
      it "should return success" do
        allow_any_instance_of(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:is_renewing_employer?).and_return(false)
        sign_in user_with_broker_role
        benefit_application.benefit_sponsorship.update_attributes(initial_enrollment_period: enrollment_period)
        get :new, params: {plan_design_proposal_id: plan_design_proposal.id, profile_id: broker_agency_profile.id}
        expect(response).to have_http_status(:success)
      end
    end
  end
end
