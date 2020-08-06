# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::Employers::EmployerStaffRolesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:staff_class) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:new_benefit_sponsor) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)    { benefit_sponsor.employer_profile }

    let!(:active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:person) { FactoryBot.create(:person, employer_staff_roles: [active_employer_staff_role]) }
    let!(:new_person_for_staff) { FactoryBot.create(:person) }
    let(:applicant_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_applicant', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:applicant_person) { FactoryBot.create(:person,employer_staff_roles: [applicant_employer_staff_role]) }
    let(:user) { FactoryBot.create(:user, :person => person)}


    describe "GET new" do

      before do
        sign_in user
        get :new, xhr: true
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
            :profile_id => employer_profile.id,
            :staff => {:first_name => new_person_for_staff.first_name, :last_name => new_person_for_staff.last_name, :dob => new_person_for_staff.dob}
          }
        end

        before :each do
          sign_in user
          post :create, params: staff_params
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(edit_profiles_registration_path(id: employer_profile.id))
          expect(response.location.include?("edit")).to eq true
        end

        it "should get an notice" do
          expect(flash[:notice]).to match /Role added sucessfully/
        end
      end

      context "creating staff role with non existing person params" do

        let!(:staff_params) do
          {
            :profile_id => employer_profile.id,
            :staff => {:first_name => "first_name", :last_name => 'last_name', :dob => "10/10/1989"}
          }
        end

        before :each do
          sign_in user
          post :create, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(edit_profiles_registration_path(id: employer_profile.id))
          expect(response.location.include?("edit")).to eq true
        end

        it "should get an error" do
          expect(flash[:error]).to match /Role was not added because Person does not exist on the HBX Exchange/
        end
      end
    end

    describe "GET approve", dbclean: :after_each do

      context "approve applicant staff role" do

        let!(:staff_params) do
          {
            :id => employer_profile.id, :person_id => applicant_person.id
          }
        end

        before :each do
          sign_in user
          get :approve, params: staff_params
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(edit_profiles_registration_path(id: employer_profile.id))
          expect(response.location.include?("edit")).to eq true
        end

        it "should get an notice" do
          expect(flash[:notice]).to match /Role is approved/
        end

        it "should update employer_staff_role aasm_state to is_active" do
          applicant_employer_staff_role.reload
          expect(applicant_employer_staff_role.aasm_state).to eq "is_active"
        end

      end

      context "approving invalid staff role" do

        let!(:staff_params) do
          {
            :id => employer_profile.id, :person_id => applicant_person.id
          }
        end

        before :each do
          sign_in user
          applicant_employer_staff_role.update_attributes(aasm_state: 'is_closed')
          get :approve, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(edit_profiles_registration_path(id: employer_profile.id))
          expect(response.location.include?("edit")).to eq true
        end

        it "should get an error" do
          expect(flash[:error]).to match /Please contact HBX Admin to report this error/
        end
      end
    end


    describe "DELETE destroy", dbclean: :after_each do

      context "should deactivate staff role" do

        let!(:staff_params) do
          {
            :id => employer_profile.id, :person_id => applicant_person.id
          }
        end

        before :each do
          sign_in user
          delete  :destroy, params: staff_params
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(edit_profiles_registration_path(id: employer_profile.id))
          expect(response.location.include?("edit")).to eq true
        end

        it "should get an notice" do
          expect(flash[:notice]).to match /Staff role was deleted/
        end

        it "should update employer_staff_role aasm_state to is_active" do
          applicant_employer_staff_role.reload
          expect(applicant_employer_staff_role.aasm_state).to eq "is_closed"
        end

      end

      context "should not deactivate only staff role of employer" do

        let!(:staff_params) do
          {
            :id => employer_profile.id, :person_id => person.id
          }
        end

        before :each do
          applicant_employer_staff_role.update_attributes(benefit_sponsor_employer_profile_id: new_benefit_sponsor.employer_profile.id)
          sign_in user
          delete  :destroy, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to edit page of benefit_sponsor" do
          expect(response).to redirect_to(edit_profiles_registration_path(id: employer_profile.id))
          expect(response.location.include?("edit")).to eq true
        end

        it "should get an error" do
          expect(flash[:error]).to match(/Please add another staff role before deleting this role/)
        end
      end
    end
  end
end
