# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::GeneralAgencyProfilesController, dbclean: :after_each do
    include_context "set up broker agency profile for BQT, by using configuration settings"
    routes { SponsoredBenefits::Engine.routes }

    let(:user) { FactoryBot.create(:user)}
    let(:person) { FactoryBot.create(:person, user: user)}

    before do
      sign_in person.user
    end

    describe "GET index" do
      before do
        get :index, xhr: true, params: { id: plan_design_organization.id, broker_agency_profile_id: plan_design_organization.owner_profile_id, action_id: "plan_design_#{plan_design_organization.id}"}
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be success" do
        expect(response).to be_successful
      end
    end

    describe "POST assign" do
      before do
        post :assign, params: {ids: [plan_design_organization.id], broker_agency_profile_id: plan_design_organization.owner_profile_id, general_agency_profile_id: general_agency_profile.id}
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be redirect to employers tab" do
        expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(id: plan_design_organization.owner_profile_id))
      end
    end

    describe "POST fire" do
      before do
        post :fire, params: {id: plan_design_organization.id, broker_agency_profile_id: plan_design_organization.owner_profile_id}
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be redirect to employers tab" do
        expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(id: plan_design_organization.owner_profile_id))
      end
    end

    describe "POST set_default" do
      before do
        post :set_default, params: {broker_agency_profile_id: plan_design_organization.owner_profile_id, general_agency_profile_id: general_agency_profile.id}
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be redirect to employers tab" do
        expect(subject).to redirect_to("/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/general_agency_index?id=#{plan_design_organization.owner_profile_id}")
      end
    end

    describe "POST clear_default" do
      before do
        post :clear_default, params: {broker_agency_profile_id: plan_design_organization.owner_profile_id}
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be redirect to employers tab" do
        expect(subject).to redirect_to("/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/general_agency_index?id=#{plan_design_organization.owner_profile_id}")
      end
    end
  end
end
