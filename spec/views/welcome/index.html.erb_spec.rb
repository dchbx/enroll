require 'rails_helper'

RSpec.describe "welcome/index.html.erb", :type => :view do

  describe "a signed in user" do
    let(:user) { FactoryGirl.create(:user, oim_id: "test@enroll.com") }

    before :each do
      sign_in user
    end
    it "should has current_user oim_id" do
      render
      expect(rendered).to match /#{user.oim_id}/
      expect(rendered).not_to match /Broker Registration/
      expect(rendered).not_to match /General Agency Registration/
    end
  end

  describe "not signed in user" do
    it "shows registration if not signed in" do
      render
      expect(rendered).to match /Broker Registration/
      expect(rendered).to match /General Agency Registration/
    end

    context "with general agency disabled" do
      before :each do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
      end
      it "does not show general agency related links" do
        render
        expect(rendered).not_to match /General Agency Registration/
        expect(rendered).not_to match /General Agency Portal/
      end
    end
  end
end
