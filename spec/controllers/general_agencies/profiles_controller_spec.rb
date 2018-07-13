require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe GeneralAgencies::ProfilesController, dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:general_agency_staff) { FactoryGirl.create(:general_agency_staff_role) }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }

  before :each do
    Settings.aca.general_agency_enabled = true
    Enroll::Application.reload_routes!
  end

  describe "GET new" do
    it "should redirect without login" do
      get :new
      expect(response).to have_http_status(:redirect)
    end

    it "should render the new template" do
      allow(controller).to receive(:check_general_agency_profile_permissions_new).and_return true
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
      expect(flash[:notice]).to eq "You don't have a General Agency Profile associated with your Account!! Please register your General Agency first."
      expect(response).to render_template("new")
    end
  end

  describe "GET index" do
    it "should redirect without login" do
      get :index
      expect(response).to have_http_status(:redirect)
    end

    it "should render the index template" do
      allow(controller).to receive(:check_general_agency_profile_permissions_index).and_return true
      sign_in(user)
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end
  end

  describe "patch update" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["general_agency_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_general_agency_staff_role) }
    let(:general_agency_staff) { person.general_agency_staff_roles.last }
    let(:org) { GeneralAgencyProfile.find( person.general_agency_staff_roles.first.general_agency_profile_id).organization}
    let(:general_agency_staff_role) { person.general_agency_staff_roles.first }
    let(:general_agency_profile){ GeneralAgencyProfile.find( person.general_agency_staff_roles.first.general_agency_profile_id) }
    before :each do
      sign_in user
      allow(controller).to receive(:sanitize_agency_profile_params).and_return(true)
      allow(controller).to receive(:authorize).and_return(true)
    end

    it "should update person main phone" do
      general_agency_profile.primary_staff.person.phones[0].update_attributes(kind: "phone main")
      post :update, id: general_agency_profile.id, organization: {id: org.id, first_name: "updated name", last_name: "updates", office_locations_attributes: {"0"=>
                                                                                                                                                               {"address_attributes"=>{"kind"=>"primary", "address_1"=>"234 nfgjkhghf", "address_2"=>"", "city"=>"jfhgdfhgjgdf", "state"=>"DC", "zip"=>"35645"},
                                                                                                                                                                "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"564", "number"=>"111-1111", "extension"=>"111"}}}}
      general_agency_profile.primary_staff.person.reload
      expect(general_agency_profile.primary_staff.person.phones[0].extension).to eq "111"
    end

    it "should update person record" do
      post :update, id: general_agency_profile.id, organization: {id: org.id, first_name: "updated name", last_name: "updates", office_locations_attributes: {"0"=>
                                                                                                                                                               {"address_attributes"=>{"kind"=>"primary", "address_1"=>"234 nfgjkhghf", "address_2"=>"", "city"=>"jfhgdfhgjgdf", "state"=>"DC", "zip"=>"35645"},
                                                                                                                                                                "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"564", "number"=>"111-1111", "extension"=>"111"}}}}
      general_agency_profile.primary_staff.person.reload
      expect(general_agency_profile.primary_staff.person.first_name).to eq "updated name"
    end
  end

  describe "GET new_agency" do
    it "should render the new_agency template" do
      get :new_agency
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new_agency")
    end

    it "should get organization" do
      get :new_agency
      expect(assigns(:organization).class).to eq Forms::GeneralAgencyProfile
    end
  end

  describe "GET new_agency_staff" do
    it "should render the new_agency_staff template" do
      get :new_agency_staff
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new_agency_staff")
    end

    it "should get organization" do
      get :new_agency_staff
      expect(assigns(:organization).class).to eq Forms::GeneralAgencyProfile
    end
  end

  describe "GET search_general_agency" do
    it "should returns http success" do
      xhr :get, :search_general_agency, general_agency_search: 'general_agency', format: :js
      expect(response).to have_http_status(:success)
    end

    it "should get general_agency_profile" do
      Organization.delete_all
      ga = FactoryGirl.create(:general_agency_profile)
      xhr :get, :search_general_agency, general_agency_search: ga.legal_name, format: :js
      expect(assigns[:general_agency_profiles]).to eq [ga]
    end
  end

  describe "GET show" do
    before(:each) do
      FactoryGirl.create(:announcement, content: "msg for GA", audiences: ['GA'])
      allow(user).to receive(:has_general_agency_staff_role?).and_return true
      sign_in(user)
      get :show, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the show template" do
      expect(response).to render_template("show")
    end

    it "should get provider" do
      expect(assigns[:provider]).to eq person
    end

    it "should get staff_role" do
      expect(assigns[:staff_role]).to eq user.has_general_agency_staff_role?
    end

    it "should get announcement" do
      expect(flash.now[:warning]).to eq ["msg for GA"]
    end
  end

  describe "GET employers" do
    before(:each) do
      sign_in(user)
      xhr :get, :employers, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the employers template" do
      expect(response).to render_template("employers")
    end

    it "should get employers" do
      #expect(assigns[:employers]).to eq general_agency_profile.employer_clients
    end
  end

  describe "GET families" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    before(:each) do
      allow(GeneralAgencyProfile).to receive(:find).and_return(general_agency_profile)
      allow(general_agency_profile).to receive(:families).and_return [family]
      sign_in(user)
    end

    context "without page params" do
      let(:person2) { FactoryGirl.create(:person , :last_name => "smith11") } # last name has to be in small case
      let(:family2) { FactoryGirl.create(:family, :with_primary_family_member , :person => person2  ) }
      before(:each) do
        allow(general_agency_profile).to receive(:families).and_return [family,family2]
        xhr :get, :families, id: general_agency_profile.id
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the families template" do
        expect(response).to render_template("families")
      end

      it "should get families" do
        # expect(assigns[:families]).to eq general_agency_profile.families
        # expect(assigns[:families]).to eq [family,family2]
      end

      it "should assign uniq page_alphabets" do
        #expect(assigns[:page_alphabets]).to eq ["S"]
      end
    end

    # context "with page params" do
    #   it "should get family" do
    #     page = family.primary_applicant.person.last_name.first
    #     xhr :get, :families, id: general_agency_profile.id, page: page
    #     expect(response).to render_template("families")
    #     expect(assigns[:families]).to eq [family]
    #   end

    #   it "should get family with full_name" do
    #     full_name = family.primary_applicant.person.full_name
    #     xhr :get, :families, id: general_agency_profile.id, q: full_name
    #     expect(response).to render_template("families")
    #     expect(assigns[:families]).to eq [family]
    #   end

    #   it "should not get family" do
    #     page = family.primary_applicant.person.last_name.first
    #     xhr :get, :families, id: general_agency_profile.id, page: '1'
    #     expect(page).not_to eq '1'
    #     expect(response).to render_template("families")
    #     expect(assigns[:families]).to eq []
    #   end
    # end
  end

  describe "GET staffs" do
    before(:each) do
      sign_in(user)
      xhr :get, :staffs, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the staffs template" do
      expect(response).to render_template("staffs")
    end

    it "should get staffs" do
      expect(assigns[:staffs]).to eq general_agency_profile.general_agency_staff_roles
    end
  end

  describe "GET edit_staff" do
    before(:each) do
      sign_in(user)
      xhr :get, :edit_staff, id: general_agency_staff.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the staffs template" do
      expect(response).to render_template("edit_staff")
    end
  end

  describe "POST update_staff" do
    before(:each) do
      FactoryGirl.create(:hbx_profile) if HbxProfile.count == 0
      sign_in(user)
      post :update_staff, id: general_agency_staff.id, approve: 'true'
    end

    it "should redirect" do
      expect(response).to have_http_status(:redirect)
    end

    it "should get notice" do
      expect(flash[:notice]).to eq "Staff approved successfully."
    end

    it "should change staff status" do
      general_agency_staff.reload
      expect(general_agency_staff.aasm_state).to eq 'active'
    end
  end

  describe "GET messages" do
    before(:each) do
      sign_in(user)
      xhr :get, :messages
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the messages template" do
      expect(response).to render_template("messages")
    end

    it "should get provider" do
      expect(assigns(:provider)).to eq person
    end
  end

  describe "GET agency_messages" do
    before(:each) do
      sign_in(user)
      xhr :get, :agency_messages, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the agency_messages template" do
      expect(response).to render_template("agency_messages")
    end
  end

  describe "GET inbox" do
    before(:each) do
      sign_in(user)
      xhr :get, :inbox, id: general_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the inbox template" do
      expect(response).to render_template("inbox")
    end

    it "should get general_agency_profile" do
      expect(assigns(:general_agency_provider)).to eq general_agency_profile
    end

    it "should get provider" do
      expect(assigns(:provider)).to eq general_agency_profile
    end
  end

  describe "POST create" do
    let(:form) { double("organization") }
    before do
      allow(::Forms::GeneralAgencyProfile).to receive(:new).and_return(form)
      sign_in(user)
    end

    it "should redirect" do
      allow(form).to receive(:save).and_return true
      post :create, organization: {first_name: 'test'}
      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to eq "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
    end

    it "should render new_agency template" do
      allow(form).to receive(:save).and_return false
      allow(form).to receive(:only_staff_role?).and_return false
      post :create, organization: {first_name: 'test'}
      expect(response).to render_template("new_agency")
    end

    it "should render new_agency_staff template" do
      allow(form).to receive(:save).and_return false
      allow(form).to receive(:only_staff_role?).and_return true
      post :create, organization: {first_name: 'test'}
      expect(response).to render_template("new_agency_staff")
    end
  end
end
end
