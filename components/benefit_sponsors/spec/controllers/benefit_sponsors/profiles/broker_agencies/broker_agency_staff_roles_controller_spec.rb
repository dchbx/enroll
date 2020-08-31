require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyStaffRolesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    before do
      DatabaseCleaner.clean
    end

    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:broker_agency_profile1) { organization.broker_agency_profile }

    let!(:second_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:second_broker_agency_profile) { second_organization.broker_agency_profile }

    let(:bap_id) { organization.broker_agency_profile.id }
    let(:user) { FactoryBot.create(:user)}
    let!(:new_person_for_staff) { FactoryBot.create(:person) }
    let!(:new_person_for_staff1) { FactoryBot.create(:person, user: user) }
    let!(:broker_role1) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: new_person_for_staff) }
    let!(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff1) }
    let!(:broker_agency_staff_role1) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff) }

    let(:staff_class) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "GET new" do

      before do
        allow(controller).to receive(:set_ie_flash_by_announcement).and_return true
        get :new, params: { profile_type: "broker_agency_staff" }
      end


      it "should render new template" do
        expect(response).to render_template("new")
      end

      it "should initialize staff" do
        expect(assigns(:staff).class).to eq staff_class
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST create", dbclean: :after_each do

      context "creating staff role with existing person params" do

        let!(:staff_params) do
          {
            profile_type: "broker_agency_staff",
            broker_registration_page: "true",
            :staff => {:first_name => new_person_for_staff.first_name, :last_name => new_person_for_staff.last_name, :dob => new_person_for_staff.dob, email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        before :each do
          post :create, params: staff_params, format: :js, xhr: true
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should render js template" do
          expect(response.content_type).to eq Mime[:js]
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end

      context 'person is already assigned as a staff to broker' do

        let!(:staff_params) do
          {
            profile_type: 'broker_agency_staff',
            broker_registration_page: 'true',
            :staff => {:first_name => new_person_for_staff1.first_name, :last_name => new_person_for_staff1.last_name, :dob => new_person_for_staff1.dob, email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        before :each do
          post :create, params: staff_params, format: :js, xhr: true
        end

        it 'should render js template' do
          expect(response.content_type).to eq Mime[:js]
        end


        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end

      context 'creating staff role with new person params' do

        let!(:staff_params) do
          {
            profile_type: 'broker_agency_staff',
            broker_registration_page: 'true',
            :staff => {:first_name => "hello", :last_name => "world", :dob => "10/10/1998", email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        before :each do
          post :create, params: staff_params, format: :js, xhr: true
        end

        it 'should render js template' do
          expect(response.content_type).to eq Mime[:js]
        end

        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end
    end

    describe "GET approve", dbclean: :after_each do

      context "approve applicant staff role" do

        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff.id, :profile_id => bap_id
          }
        end

        before :each do
          sign_in user
          broker_agency_staff_role1.update_attributes(aasm_state: 'broker_agency_pending')
          get :approve, params: staff_params
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should get an notice" do
          expect(flash[:notice]).to match 'Role approved successfully'
        end

        it "should update broker_agency_staff_role aasm_state to active" do
          broker_agency_staff_role1.reload
          expect(broker_agency_staff_role1.aasm_state).to eq "active"
        end

      end

      context "approving invalid staff role" do

        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
          }
        end

        before :each do
          sign_in user
          broker_agency_staff_role.update_attributes(aasm_state: 'active')
          get :approve, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should get an error" do
          expect(flash[:error]).to match 'Please contact HBX Admin to report this error'
        end
      end
    end


    describe "DELETE destroy", dbclean: :after_each do
      context "should deactivate staff role" do

        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
          }
        end

        before :each do
          sign_in user
          broker_agency_staff_role.update_attributes(aasm_state: 'active')
          delete :destroy, params: staff_params
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should get an notice" do
          expect(flash[:notice]).to match 'Role removed successfully'
        end

        it "should update broker_staff_rol aasm_state to broker_agency_terminated" do
          broker_agency_staff_role.reload
          expect(broker_agency_staff_role.aasm_state).to eq "broker_agency_terminated"
        end
      end

      context "should not deactivate only staff role of broker" do

        let!(:staff_params) do
          {
            :id => second_broker_agency_profile.id, :person_id => new_person_for_staff1.id, :profile_id => second_broker_agency_profile.id
          }
        end

        before :each do
          broker_agency_staff_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id, aasm_state: 'active')
          sign_in user
          delete :destroy, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should get an error" do
          expect(flash[:error]).to match(/Role was not removed because/i)
        end
      end
    end

    describe "GET search_broker_agency" do

      before do
        Person.create_indexes
        broker_agency_profile1.update_attributes!(primary_broker_role_id: broker_role1.id)
        broker_agency_profile1.approve!
        organization.reload
        get :search_broker_agency, params: params, format: :js, xhr: true
      end

      context "return result if broker agency is present" do

        let!(:params) do
          {
            q: broker_agency_profile1.legal_name,
            broker_registration_page: "true"
          }
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('search_broker_agency')
        end

        it 'should assign broker_agency_profiles variable' do
          expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile1)
        end
      end

      context "should not return result" do

        let!(:params) do
          {
            q: "hello world",
            broker_registration_page: "true"
          }
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('search_broker_agency')
        end

        it 'should assign broker_agency_profiles variable' do
          expect(assigns(:broker_agency_profiles)).not_to include(broker_agency_profile1)
        end
      end
    end

  end
end
