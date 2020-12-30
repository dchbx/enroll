require 'rails_helper'

RSpec.describe BrokerAgencies::InboxesController, :type => :controller, dbclean: :after_each do
  let(:hbx_profile) { FactoryBot.create(:benefit_sponsors_organizations_hbx_profile)}
  let(:user) { double("user") }
  let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:employer_profile)    { benefit_sponsor.employer_profile }
  let!(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
  let!(:person) { FactoryBot.create(:person, employer_staff_roles:[active_employer_staff_role]) }
  let!(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile) }

  describe "Get new" do
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"), inbox: double(messages: double(build: double("inbox"))))}
    before do
      sign_in user
      allow(Person).to receive(:find).and_return(inbox_provider)
      allow(BrokerAgencyProfile).to receive(:where).and_return(inbox_provider)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:_id).and_return('xxx')
    end

    it "render new template" do
      get :new, params: {id: broker_agency_profile.id.to_s, profile_id: hbx_profile.id, to: "test"}, format: :js, xhr: true
      expect(response).to render_template("new")
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST create" do
    let(:inbox){Inbox.new}
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"))}
    let(:valid_params){{"message"=>{"subject"=>"test", "body"=>"test", "sender_id"=>"558b63ef4741542b64290000", "from"=>"HBXAdmin", "to"=>"Acme Inc."}}}
    let!(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile)}
    before do
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      allow(Person).to receive(:find).and_return(inbox_provider)
      allow(BrokerAgencyProfile).to receive(:find).and_return(inbox_provider)
      allow(BenefitSponsors::Organizations::HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(inbox_provider).to receive(:inbox).and_return(inbox)
      allow(inbox_provider.inbox).to receive(:post_message).and_return(inbox)
      allow(hbx_profile).to receive(:inbox).and_return(inbox)
      allow(person).to receive(:_id).and_return('xxx')
    end

    it "creates new message" do
      allow(inbox_provider.inbox).to receive(:save).and_return(true)
      valid_params[:id] = "id"
      post :create, params: valid_params
      expect(response).to have_http_status(:redirect)
    end

    it "creates new message to hbx admin" do
      allow(inbox_provider.inbox).to receive(:save).and_return(true)
      valid_params.deep_merge!(message:{to: "HBX Admin"}, id: inbox_provider.id)
      valid_params[:id] = "id"
      valid_params[:profile_id] = hbx_profile.id
      post :create, params: valid_params
      expect(response).to have_http_status(:redirect)
    end

    it "renders new template of broker agency" do
      allow(inbox_provider.inbox).to receive(:save).and_return(false)
      valid_params.deep_merge!(message:{to: "HBX Admin"}, id: inbox_provider.id)
      post :create, params: valid_params
      expect(response).to render_template(:new)
    end
  end

  describe "GET message_to_portal" do
    let(:broker_agency_profile) { double("BrokerAgencyProfile", legal_name: "my broker name") }
    let(:inbox){ double("Inbox") }
    let(:messages){ double("Message", build: double("test")) }
    let(:organization){ FactoryBot.create(:organization) }
    let(:hbx_profile){ double("HbxProfile") }
    it "renders" do
      sign_in
      allow(BrokerAgencyProfile).to receive(:find).and_return(broker_agency_profile)
      allow(broker_agency_profile).to receive(:inbox).and_return(inbox)
      allow(inbox).to receive(:messages).and_return(messages)
      get :msg_to_portal, params: {inbox_id:1}, xhr: true
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show / DELETE destroy" do
    let(:message){double(to_a: double("to_array"))}
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"))}
    before do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      sign_in(user)
      allow(BrokerAgencyProfile).to receive(:find).and_return(inbox_provider)
      allow(Person).to receive(:find).and_return(inbox_provider)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
      allow(person).to receive(:_id).and_return('xxx')
    end

    it "show action" do
      get :show, params:{id: 1}
      expect(response).to have_http_status(:success)
    end

    it "delete action" do
      delete :destroy, params:{id:1}, xhr:true
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show on Message with no Profile" do
    let(:message){double(to_a: double("to_array"))}
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"))}
    let(:id){double(id: "1")}
    before do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      sign_in(user)
      allow(BrokerAgencyProfile).to receive(:find).and_return(nil)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
      allow(Person).to receive(:find).and_return(id)
    end

    it "show action" do
      get :show, params: {id: id}
      expect(response).to have_http_status(:success)
    end
  end
end
