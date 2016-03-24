require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesController do
  let(:broker_agency_profile_id) { "abecreded" }
  let!(:broker_agency) { FactoryGirl.create(:broker_agency) }
  let(:broker_agency_profile) { broker_agency.broker_agency_profile }

  describe "GET new" do
    let(:user) { double("user", last_portal_visited: "test.com")}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      allow(user).to receive(:has_broker_role?).and_return(false)
      allow(user).to receive(:last_portal_visited=).and_return("true")
      allow(user).to receive(:save).and_return(true)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show" do
    let(:user) { double("user")}
    let(:person) { double("person")}

    before(:each) do
      allow(user).to receive(:has_broker_role?)
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(true)
      sign_in(user)
      get :show, id: broker_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the show template" do
      expect(response).to render_template("show")
    end
  end

  describe "GET edit" do
    let(:user) { double(has_broker_role?: true)}

    before :each do
      sign_in user
      get :edit, id: broker_agency_profile.id
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the edit template" do
      expect(response).to render_template("edit")
    end
  end

  describe "patch update" do
    let(:user) { double(has_broker_role?: true)}
    #let(:org) { double }
    let(:org) { double("Organization", id: "test") }

    before :each do
      sign_in user
      #allow(Forms::BrokerAgencyProfile).to receive(:find).and_return(org)
      allow(Organization).to receive(:find).and_return(org)
      allow(controller).to receive(:sanitize_broker_profile_params).and_return(true)
    end

    it "should success with valid params" do
      allow(org).to receive(:update_attributes).and_return(true)
      #post :update, id: broker_agency_profile.id, organization: {}
      #expect(response).to have_http_status(:redirect)
      #expect(flash[:notice]).to eq "Successfully Update Broker Agency Profile"
    end

    it "should failed with invalid params" do
      allow(org).to receive(:update_attributes).and_return(false)
      #post :update, id: broker_agency_profile.id, organization: {}
      #expect(response).to render_template("edit")
      #expect(response).to have_http_status(:redirect)
      #expect(flash[:error]).to eq "Failed to Update Broker Agency Profile"
    end
  end

  describe "GET index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_broker_agency_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_broker_role?).and_return(false)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :index
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "renders the 'index' template" do
      expect(response).to render_template("index")
    end
  end

  describe "CREATE post" do
    let(:user){ double(:save => double("user")) }
    let(:person){ double(:broker_agency_contact => double("test")) }
    let(:broker_agency_profile){ double("test") }
    let(:form){double("test", :broker_agency_profile => broker_agency_profile)}
    let(:organization) {double("organization")}
    context "when no broker role" do
      before(:each) do
        allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
        allow(user).to receive(:has_broker_role?).and_return(false)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:person).and_return(person)
        sign_in(user)
        allow(Forms::BrokerAgencyProfile).to receive(:new).and_return(form)
      end

      it "returns http status" do
        allow(form).to receive(:save).and_return(true)
        post :create, organization: {}
        expect(response).to have_http_status(:redirect)
      end

      it "should render new template when invalid params" do
        allow(form).to receive(:save).and_return(false)
        post :create, organization: {}
        expect(response).to render_template("new")
      end
    end

  end

  describe "REDIRECT to my account if broker role present" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}
    let(:person){double(:broker_agency_staff_roles => [double(:broker_agency_profile_id => 5)]) }

    it "should redirect to myaccount" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "get employers" do
    let(:broker_role) {FactoryGirl.build(:broker_role)}
    let(:person) {double("person", broker_role: broker_role)}
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:organization) {FactoryGirl.create(:organization)}
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }

    it "should get organizations for employers where broker_agency_account is active" do
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(true)
      sign_in user
      xhr :get, :employers, id: broker_agency_profile.id, format: :js
      expect(response).to have_http_status(:success)
      orgs = Organization.where({"employer_profile.broker_agency_accounts"=>{:$elemMatch=>{:is_active=>true, :broker_agency_profile_id=>broker_agency_profile.id}}})
      expect(assigns(:orgs)).to eq orgs
    end

    it "should get organizations for employers where writing_agent is active" do
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:person).and_return(person)
      sign_in user
      xhr :get, :employers, id: broker_agency_profile.id, format: :js
      expect(response).to have_http_status(:success)
      orgs = Organization.where({"employer_profile.broker_agency_accounts"=>{:$elemMatch=>{:is_active=>true, :writing_agent_id=> broker_role.id }}})
      expect(assigns(:orgs)).to eq orgs
    end
  end

  describe "family_index" do
    before :all do
      org = FactoryGirl.create(:organization)
      broker_agency_profile = FactoryGirl.create(:broker_agency_profile, organization: org)
      broker_role = FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id)
      person = broker_role.person
      @current_user = FactoryGirl.create(:user, person: person, roles: [:broker])
      families = []
      30.times.each do
        family = FactoryGirl.create(:family, :with_primary_family_member)
        family.hire_broker_agency(broker_role.id)
        families << family
      end
      families[0].primary_applicant.person.update_attributes!(last_name: 'Jones1')
      families[1].primary_applicant.person.update_attributes!(last_name: 'Jones2')
      families[2].primary_applicant.person.update_attributes!(last_name: 'Jones3')
    end

    it 'should render 21 familes' do
      current_user = @current_user
      allow(current_user).to receive(:has_broker_role?).and_return(true)
      sign_in current_user
      xhr :get, :family_index, id: broker_agency_profile.id
      expect(assigns(:families).count).to eq(21)
      expect(assigns(:page_alphabets)).to include("J")
      expect(assigns(:page_alphabets)).to include("S")
    end

    it "should render families starting with J" do
      current_user = @current_user
      allow(current_user).to receive(:has_broker_role?).and_return(true)
      sign_in current_user
      xhr :get, :family_index, id: broker_agency_profile.id, page: 'J'
      expect(assigns(:families).count).to eq(3)
    end

    it "should render families named Smith" do
      current_user = @current_user
      allow(current_user).to receive(:has_broker_role?).and_return(true)
      sign_in current_user
      xhr :get, :family_index, id: broker_agency_profile.id, q: 'Smith'
      expect(assigns(:families).count).to eq(27)
    end
  end

  describe "eligible_brokers" do

    before :all do
      org1 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
      broker_agency_profile1 = FactoryGirl.create(:broker_agency_profile, organization:org1, market_kind:'individual')
      FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile1.id, market_kind:'individual', aasm_state:'active')

      org2 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
      broker_agency_profile2 = FactoryGirl.create(:broker_agency_profile, organization:org2, market_kind:'shop')
      FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile2.id, market_kind:'shop', aasm_state:'active')

      org3 = FactoryGirl.create(:organization, fein: 100000000 + rand(100000))
      broker_agency_profile3 = FactoryGirl.create(:broker_agency_profile, organization:org3, market_kind:'both')
      FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile3.id, market_kind:'both', aasm_state:'active')

    end

    context "individual market user" do
      let(:person) {FactoryGirl.create(:person, is_consumer_role:true)}
      let(:user) {FactoryGirl.create(:user, person: person, roles: ['consumer'])}

      it "selects only 'individual' and 'both' market brokers" do
        allow(subject).to receive(:current_user).and_return(user)
        controller.instance_variable_set(:@person, person)
        staff = subject.instance_eval{ eligible_brokers }

        staff.each do |staff_person|
         expect(["individual", "both"].include? staff_person.broker_role.market_kind).to be_truthy
        end
      end
    end

    context "SHOP market user" do
      let(:person) {FactoryGirl.create(:person, is_consumer_role:true)}
      let(:user) {FactoryGirl.create(:user, person: person, roles: ['employer'])}

      it "selects only 'shop' and 'both' market brokers" do
        allow(subject).to receive(:current_user).and_return(user)
        controller.instance_variable_set(:@person, person)
        staff = subject.instance_eval{ eligible_brokers }

        staff.each do |staff_person|
          expect(["shop", "both"].include? staff_person.broker_role.market_kind).to be_truthy
        end
      end
    end
  end
end
