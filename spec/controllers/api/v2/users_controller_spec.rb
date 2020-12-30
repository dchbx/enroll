require "rails_helper"

RSpec.describe Api::V2::UsersController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  describe "GET current, when not logged in" do
    before :each do
      get :current
    end

    it "is unauthorized" do
      expect(response.status).to eq 401
    end
  end

  describe "GET current" do
    let(:user_data_hash) do
      {
        account_name: user.oim_id
      }
    end

    let(:operation) do
      instance_double(
        Operations::SerializeCurrentUserResource,
        call: user_data_hash
      )
    end

    before :each do
      sign_in(user)
      allow(Operations::SerializeCurrentUserResource).to receive(:new).with(user).and_return(operation)
      get :current
    end

    it "is successful" do
      expect(response.status).to eq 200
    end

    it "renders the user" do
      expect(response.body).to eq user_data_hash.to_json
    end
  end
end