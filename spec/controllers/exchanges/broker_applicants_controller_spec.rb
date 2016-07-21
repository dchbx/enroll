require 'rails_helper'

RSpec.describe Exchanges::BrokerApplicantsController do

  describe ".index" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      xhr :get, :index, format: :js
    end

    it "should render index" do
      expect(assigns(:broker_applicants))
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/broker_applicants/index")
    end

    context 'when hbx staff role missing' do
      let(:user) { instance_double("User", :has_hbx_staff_role? => false) }

      it 'should redirect when hbx staff role missing' do 
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end
  end

  describe ".edit" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }
    let(:broker_role) {FactoryGirl.create(:broker_role)}

    before :each do
      sign_in(user)
      xhr :get, :edit, id: broker_role.person.id, format: :js
    end

    it "should render edit" do
      expect(assigns(:broker_applicant))
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/broker_applicants/edit")
    end
  end

  describe ".update" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }
    let(:broker_role) {FactoryGirl.create(:broker_role)}

    before :all do 
      @broker_agency_profile = FactoryGirl.create(:broker_agency).broker_agency_profile
    end

    before :each do
      @broker_agency_profile.update_attributes({ primary_broker_role: broker_role })
      sign_in(user)
    end

    context 'when application denied' do
      before :each do
        put :update, id: broker_role.person.id, deny: true, format: :js
        broker_role.reload
      end

      it "should change applicant status to denied" do
        expect(assigns(:broker_applicant))
        expect(broker_role.aasm_state).to eq 'denied'
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end

    context 'when application approved and applicant is not primary broker' do

      before :each do
        FactoryGirl.create(:hbx_profile)
        put :update, id: broker_role.person.id, approve: true, format: :js
        broker_role.reload
      end

      it "should approve and change status to broker agency pending" do
        allow(broker_role).to receive(:broker_agency_profile).and_return(@broker_agency_profile)

        expect(assigns(:broker_applicant))
        expect(broker_role.aasm_state).to eq 'broker_agency_pending'
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end

    context 'when applicant is a primary broker' do
      let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role_id: broker_role.id) }

      context 'when application is approved' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          put :update, id: broker_role.person.id, approve: true, format: :js
          broker_role.reload
        end

        it "should change applicant status to active" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'active'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end

      context 'when application is pending' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          put :update, id: broker_role.person.id, pending: true, person:  { broker_role_attributes: { training: true , carrier_appointments: {}} } , format: :js
          broker_role.reload
        end

        it "should change applicant status to broker_agency_pending" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'broker_agency_pending'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end

      context 'when application is decertified' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          broker_role.approve!
          put :update, id: broker_role.person.id, decertify: true, format: :js
          broker_role.reload
        end

        it "should change applicant status to decertified" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'decertified'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end
    end
  end
end