require 'rails_helper'

RSpec.describe GeneralAgencies::InboxesController, dbclean: :after_each do
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }

  before :each do
    Settings.aca.general_agency_enabled = true
    Enroll::Application.reload_routes!
  end
  
  describe "Get new" do
    before do
      sign_in user
      xhr :get, :new, :id => general_agency_profile.id, profile_id: hbx_profile.id, to: "test", format: :js
    end

    it "render new template" do
      expect(response).to render_template("new")
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET message_to_portal" do
    let(:inbox){ double("Inbox") }
    let(:messages){ double("Message", build: double("test")) }

    it "renders" do
      sign_in
      allow(GeneralAgencyProfile).to receive(:find).and_return(general_agency_profile)
      allow(general_agency_profile).to receive(:inbox).and_return(inbox)
      allow(inbox).to receive(:messages).and_return(messages)
      xhr :get, :msg_to_portal, inbox_id: general_agency_profile.id
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET show / DELETE destroy" do
    let(:message){double(to_a: double("to_array"))}
    let(:inbox_provider){double(id: double("id"),legal_name: double("inbox_provider"))}

    before do
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      allow(GeneralAgencyProfile).to receive(:find).and_return(inbox_provider)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
      allow(person).to receive(:_id).and_return('xxx')
    end

    it "show action" do
      xhr :get, :show, id: 1
      expect(response).to have_http_status(:success)
    end

    it "delete action" do
      xhr :delete, :destroy, id: 1
      expect(response).to have_http_status(:success)
    end
  end
end
