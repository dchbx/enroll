require 'rails_helper'

RSpec.describe InvitationsController do
  let(:user) { instance_double("User") }
  let(:invitation_id) { "an invitation id" }
  let(:invitation) { instance_double(Invitation, :may_claim? => unclaimed) }

  describe "GET claim" do

    before(:each) do
      allow(user).to receive(:person).and_return nil
      sign_in(user)
      allow(Invitation).to receive(:find).with(invitation_id).and_return(invitation)
    end

    describe "with an already claimed invitation" do
      let(:unclaimed) { false }

      it "should redirect back to the welcome page with an error" do
        get :claim, params: {id: invitation_id}
        expect(response).to redirect_to(root_url)
        expect(flash[:error]).to eq "Invalid invitation."
      end
    end

    describe "with a valid, unclaimed invitation" do
      let(:unclaimed) { true }

      it "should claim the invitation" do
        expect(invitation).to receive(:claim_invitation!).with(user, controller) do |u, c|
          c.redirect_to root_url
        end
        get :claim, params: {id: invitation_id}
        expect(response).to redirect_to(root_url)
      end
    end

    describe 'with a valid invitation for already existing user' do
      context "broker invitation" do
        let(:user) { FactoryBot.create(:user) }
        let(:person) { FactoryBot.create(:person, user: user) }
        let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
        let!(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
        let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
        let!(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active', person: person)}
        let(:invitation) { FactoryBot.create(:invitation, :broker_role, :source_id => broker_agency_profile.id)}
        let(:params) { {id: invitation.id, person_id: person.id }}

        before(:each) do
          sign_in(user)
          allow(Invitation).to receive(:find).with(invitation.id).and_return(invitation)
        end

        it 'should redirect to sign in page if already person with user record is present' do
          invitation.source_id = broker_agency_staff_role.id
          get :claim, params: params
          expect(response).to redirect_to(new_user_session_url(:invitation_id => params[:id]))
        end
      end

      context "general agency invitation" do
        let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
        let!(:general_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
        let(:general_agency_profile) { general_agency_organization.general_agency_profile }
        let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: 'active', person: ga_person)}
        let(:ga_user) { FactoryBot.create(:user) }
        let(:ga_person) { FactoryBot.create(:person, user: ga_user) }
        let(:invitation) { FactoryBot.create(:invitation, :general_agency_staff_role, :source_id => general_agency_profile.id)}
        let(:params) { {id: invitation.id, person_id: ga_person.id }}

        before(:each) do
          sign_in(user)
          allow(Invitation).to receive(:find).with(invitation.id).and_return(invitation)
        end

        it 'should redirect to sign in page if already person with user record is present' do
          invitation.source_id = general_agency_staff_role.id
          get :claim, params: params
          expect(response).to redirect_to(new_user_session_url(:invitation_id => params[:id]))
        end
      end
    end

  end
end
