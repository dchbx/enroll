require 'rails_helper'

RSpec.describe Insured::InboxesController, :type => :controller do
  let(:hbx_profile) { FactoryBot.create(:benefit_sponsors_organizations_hbx_profile)}
  let(:user) { double('user') }
  let(:person) { double(:employer_staff_roles => [double('person', :employer_profile_id => double)], agent?: false)}

  describe 'Get new' do
    let(:inbox_provider){double(id: double('id'),full_name: double('inbox_provider'), inbox: double(messages: double(build: double('inbox'))))}
    before do
      sign_in
      allow(Person).to receive(:find).and_return(inbox_provider)
    end

    it 'render new template' do
      get :new, params: {id: inbox_provider.id, profile_id: hbx_profile.id, to: 'test'}, format: :js, xhr: true
      expect(response).to render_template('new')
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST create' do
    let(:inbox){Inbox.new}
    let(:inbox_provider){double(id: double("id"),full_name: double("inbox_provider"))}
    let(:valid_params){{'subject'=>'test', 'body'=>'test', 'sender_id'=>'558b63ef4741542b64290000', 'from'=>'HBXAdmin', 'to'=>'Acme Inc.'}}
    before do
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      allow(Person).to receive(:find).and_return(inbox_provider)
      allow(inbox_provider).to receive(:inbox).and_return(inbox)
      allow(inbox_provider.inbox).to receive(:post_message).and_return(inbox)
      allow(inbox_provider.inbox).to receive(:save).and_return(true)
      allow(hbx_profile).to receive(:inbox).and_return(inbox)
    end

    it 'creates new message' do
      post :create, params: {id: inbox_provider.id, profile_id: hbx_profile.id, message: valid_params}
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET show / DELETE destroy' do
    let(:message){double(to_a: double('to_array'), message_read: false)}
    let(:inbox_provider){double(id: double('id'),full_name: double('inbox_provider'))}
    before do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      sign_in(user)
      allow(Person).to receive(:find).and_return(inbox_provider)
      allow(controller).to receive(:find_message)
      controller.instance_variable_set(:@message, message)
      allow(message).to receive(:update_attributes).and_return(true)
    end

    context 'admin user GET show' do
      before do
        allow(user).to receive(:has_hbx_staff_role?).and_return(true)
        it 'show action' do
          get :show, params: {id: 1}
          expect(response).to have_http_status(:success)
          expect(message.message_read).to eq(true)
        end
      end
    end

    it 'show action' do
      get :show, params: {id: 1}
      expect(response).to have_http_status(:success)
      expect(message.message_read).to eq(false)
    end

    it 'delete action' do
      delete :destroy, params: {id: 1}, xhr: true
      expect(response).to have_http_status(:success)
    end
  end
end
