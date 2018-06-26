require 'rails_helper'

RSpec.describe "welcome/index.html.slim", :type => :view, dbclean: :after_each  do
  let(:user) { FactoryGirl.create(:user, oim_id: "test@enroll.com") }

  describe "a signed in user" do
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
    context "with general agency enabled" do
      before :each do
        Settings.aca.general_agency_enabled = true
        Enroll::Application.reload_routes!
        render
      end
      it "shows registration if not signed in" do
        expect(rendered).to match /Broker Registration/
        expect(rendered).to match /General Agency Registration/
      end
    end

    context "with general agency disabled" do
      before :each do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
        render
      end
      it "does not show general agency related links" do
        expect(rendered).not_to match /General Agency Registration/
        expect(rendered).not_to match /General Agency Portal/
      end
    end

    context "with enabled IVL market" do
      before do
        Settings.aca.market_kinds = %w[individual shop]
        Enroll::Application.reload_routes!

        allow(view).to receive(:general_agency_enabled?).and_return(false)
        render
      end

      it "shows the Consumer portal link" do
        expect(rendered).to have_link('Consumer/Family Portal')
      end

      it "shows the Assistest consumer portal link" do
        expect(rendered).to have_link('Assisted Consumer/Family Portal')
      end
    end

    context "with disabled IVL market" do
      before do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
        allow(view).to receive(:individual_market_is_enabled?).and_return(false)
        render
      end
      it "does not show the Consumer portal links" do
        expect(rendered).not_to have_link('Consumer/Family Portal')
      end
      it "does not show the Assisted consumer portal link" do
        expect(rendered).not_to have_link('Assisted Consumer/Family Portal')
      end
    end
  end
end
