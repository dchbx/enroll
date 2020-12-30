require 'rails_helper'

RSpec.describe Api::V2::AuthTokensController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  describe "DELETE logout, when logged in" do
    before :each do
      sign_in(user)
    end

    it "is successful" do
      delete :logout
      expect(response.status).to eq 200
    end
  end

  describe "DELETE logout, when NOT logged in" do
    it "is denied" do
      delete :logout
      expect(response.status).to eq 401
    end
  end

  describe "POST refresh, when NOT logged in" do
    it "is denied" do
      post :refresh
      expect(response.status).to eq 401
    end
  end

  describe "POST refresh, when logged in" do
    before :each do
      sign_in(user)
    end

    it "is successful" do
      post :refresh
      expect(response.status).to eq 200
    end

    it "renders the new jwt" do
      post :refresh
      body_json = JSON.parse(response.body)
      expect(body_json["jwt"]).not_to be_empty
    end
  end
end