require 'rails_helper'

RSpec.describe Exchanges::ResidentsController, :type => :controller do
  let(:user){ FactoryGirl.create(:user, :resident) }
  let(:person){ FactoryGirl.create(:person) }
  let(:family){ double("Family") }
  let(:family_member){ double("FamilyMember") }
  let(:resident_role){ FactoryGirl.build(:resident_role) }
  let(:bookmark_url) {'localhost:3000'}
  let(:permission) { FactoryGirl.create(:permission, :hbx_staff) }
  let(:read_only_permission) { FactoryGirl.create(:permission, :hbx_read_only) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: permission.id)}
  let(:hbx_read_only_role) { FactoryGirl.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: read_only_permission.id)}

  describe "Get search" do
    let(:mock_resident_candidate) { instance_double("Forms::ResidentCandidate", dob: "12/26/1975") }

    before(:each) do
      allow(Forms::ResidentCandidate).to receive(:new).and_return(mock_resident_candidate)
      allow(user).to receive(:last_portal_visited=)
      allow(user).to receive(:save!).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(person).to receive(:resident_role).and_return(resident_role)
      allow(person).to receive(:is_resident_role_active?).and_return(false)
      allow(resident_role).to receive(:save!).and_return(true)
      sign_in user
    end

    it "should render search template" do
      get :search
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)
    end
  end

  context "GET edit" do
    before(:each) do
      allow(ResidentRole).to receive(:find).and_return(resident_role)
      allow(resident_role).to receive(:person).and_return(person)
      allow(resident_role).to receive(:build_nested_models_for_person).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:resident_role).and_return(resident_role)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(resident_role).to receive(:save!).and_return(true)
      allow(resident_role).to receive(:bookmark_url=).and_return(true)
    end
    it "should render edit template" do
      sign_in user
      get :edit, id: "test"
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end
  end

  context "PUT update" do
    let(:person_params){{"dob"=>"1985-10-01", "first_name"=>"Nikola","gender"=>"male","last_name"=>"Rasevic","middle_name"=>"Veljko"}}
    before(:each) do
      allow(ResidentRole).to receive(:find).and_return(resident_role)
      allow(resident_role).to receive(:build_nested_models_for_person).and_return(true)
      allow(resident_role).to receive(:person).and_return(person)
      allow(user).to receive(:person).and_return person
      allow(person).to receive(:resident_role).and_return resident_role
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      sign_in user
    end

    it "should update existing person" do
      allow(resident_role).to receive(:update_by_person).and_return(true)
      put :update, person: person_params, id: "test"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(ridp_bypass_exchanges_residents_path)
    end
  end

  context "Get begin_resident_enrollment" do
    before(:each) do
      allow(user).to receive(:person).and_return person
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      sign_in user
    end

    it "should redirect to search_exchanges_residents_path template" do
      get :begin_resident_enrollment
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(search_exchanges_residents_path)
    end
  end

  context "Get resume_resident_enrollment" do
    before(:each) do
      allow(Person).to receive(:find).and_return(person)
      allow(person).to receive(:resident_role).and_return resident_role
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(user).to receive(:person).and_return person
      sign_in user
    end

    it "should redirect to search_exchanges_residents_path template" do
      get :resume_resident_enrollment
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(family_account_path)
    end
  end

  context "Get begin_resident_enrollment without proper permission" do
    before(:each) do
      allow(user).to receive(:person).and_return person
      allow(person).to receive(:hbx_staff_role).and_return hbx_read_only_role
      sign_in user
    end

    it "should redirect to search_exchanges_residents_path template" do
      get :begin_resident_enrollment
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(destroy_user_session_path)
    end
  end
end
