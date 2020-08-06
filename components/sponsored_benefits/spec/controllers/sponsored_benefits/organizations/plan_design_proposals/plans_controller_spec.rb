# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::PlansController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }

    include_context "set up broker agency profile for BQT, by using configuration settings"

    let(:plans) { FactoryBot.create_list(:plan, 5, :with_premium_tables, market: 'shop')}

    let(:person) do
      FactoryBot.create(:person, :with_broker_role).tap do |person|
        person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
      end
    end

    let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }

    describe "GET #index" do
      let(:carrier_profile_id) {plans.first.carrier_profile.id.to_s}

      before :each do
        sign_in user_with_broker_role
        get :index, params: {plan_design_organization_id: plan_design_organization.id, selected_carrier_level: "single_carrier", kind: "health", carrier_id: carrier_profile_id, active_year: TimeKeeper.date_of_record.year, format: :js}
      end

      it "returns a success response" do
        expect(response).to have_http_status(:success)
      end

      it "should set plans instance variable" do
        expect(assigns(:plans)).to eq [plans.first]
      end
    end
  end
end
