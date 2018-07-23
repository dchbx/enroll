require 'rails_helper'

 RSpec.describe Users::PasswordsController do
  let(:curam_user){ double("CuramUser") }
  let(:email){ "test@example.com" }
  let(:user) { FactoryGirl.create :user}

  context "create" do

   before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      allow(CuramUser).to receive(:match_unique_login).with(email).and_return([curam_user])
      user.update_attributes!(email: email)
    end

    it "should redirect to new_user_password_path" do
      post :create, { user: { email: email} }
      expect(response).to have_http_status(302)
    end
  end
 end
