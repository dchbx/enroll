require 'rails_helper'

RSpec.describe WelcomeController, :type => :controller do
  describe "GET index" do
    shared_examples "welcome" do
      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "renders welcome index" do
        expect(response).to render_template("index")
      end
    end

    context "when not signed in" do
      before do
        sign_in nil
        get :index
      end

      include_examples "welcome"
    end

    context "when signed in" do
      before do
        sign_in
        get :index
      end

      include_examples "welcome"
    end

    it "should return to a http status success" do
      get :index
      expect( response ).to have_http_status(:success)
    end
  end

  describe "POST show_hints" do
    let(:user) { FactoryGirl.build(:user) }
    it "should return to a http status success" do
      sign_in user
      xhr :post, "show_hints", :format => "js"
      expect( response ).to have_http_status(:success)
    end
  end

end
