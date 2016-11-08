require 'rails_helper'

RSpec.describe Exchanges::InboxesController do
  context "GET show / DELETE destroy" do
    let(:user) { double("User") }
    let(:person) { double("Person") }
    let(:hbx_profile) { double("HbxProfile") }
    let(:inbox) { double("Inbox") }
    let(:message){ double("Message", message_read: false ) }
    let(:inbox_provider){double(id: double("id"),full_name: double("inbox_provider"))}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
      allow(Person).to receive(:find).and_return(inbox_provider)
    end

    context "as user" do
      before :each do
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      end

      it "should render show" do
        get :show, id: "test"
        expect(response).to have_http_status(:success)
      end

      it "delete action" do
        xhr :delete, :destroy, id: 1
        expect(response).to have_http_status(:success)
      end
    end

    context "as admin" do
      before do
        allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      end

      it "should render show" do
        get :show, id: "test"
        expect(response).to have_http_status(:success)
        expect(message.message_read).to eq(false)
      end
    end
  end
end
