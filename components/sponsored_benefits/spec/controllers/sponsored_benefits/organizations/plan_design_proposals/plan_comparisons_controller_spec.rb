# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module UserRoles
  USER_ROLES = [:with_hbx_staff_role, :with_broker_role].freeze unless const_defined?(:USER_ROLES)
end

module SponsoredBenefits
  include UserRoles

  RSpec.describe Organizations::PlanDesignProposals::PlanComparisonsController, type: :controller, dbclean: :after_each  do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    routes { SponsoredBenefits::Engine.routes }

    describe "GET new" do
      let!(:person) do
        FactoryBot.create(:person, :with_broker_role).tap do |person|
          if Settings.aca.state_abbreviation == 'DC'
            person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s)
          else
            person.broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id.to_s)
          end
        end
      end

      let!(:user_with_broker_role) { FactoryBot.create(:user, person: person) }
      let(:plans) { FactoryBot.create_list(:plan, 2, :with_premium_tables, market: 'shop') }

      before :each do
        sign_in user_with_broker_role
        get :new, params: {plan_design_proposal_id: plan_design_proposal.id, sort_by: "", plans: [plans.first.id.to_s, plans.last.id.to_s], format: "js"}
      end

      it "should return success" do
        expect(response).to have_http_status(:success)
      end

      it "do not assign a qhps" do
        expect(assigns(:qhps)).to be nil
      end
    end
  end
end
