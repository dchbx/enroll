require 'rails_helper'

RSpec.describe Insured::ConsumerRolesController, :type => :controller do
  let(:user){ FactoryGirl.create(:user, :resident) }
  let(:person){ FactoryGirl.build(:person) }
  let(:family){ double("Family") }
  let(:family_member){ double("FamilyMember") }
  let(:resident_role){ FactoryGirl.build(:resident_role) }
  let(:bookmark_url) {'localhost:3000'}

  context "GET privacy" do
    before(:each) do
      sign_in user
      allow(user).to receive(:person).and_return(person)
    end
    it "should redirect" do
      allow(person).to receive(:resident_role?).and_return(true)
      allow(person).to receive(:resident_role).and_return(resident_role)
      allow(resident_role).to receive(:bookmark_url).and_return("test")
      get :privacy, {:aqhp => 'true'}
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(person.residentt_role.bookmark_url+"?aqhp=true")
    end
    it "should render privacy" do
      allow(person).to receive(:resident_role?).and_return(false)
      get :privacy
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:privacy)
    end
  end
end
