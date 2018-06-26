require "rails_helper"

RSpec.describe "broker_agencies/profiles/_menu.html.erb" do
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }

  before :each do
    sign_in(user)
    assign(:broker_agency_profile, broker_agency_profile)
    assign(:id, broker_agency_profile.id)
    assign(:provider, broker_agency_profile)
  end

  context "with hbx admin role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["hbx_staff_role"]) }
    let(:person) { FactoryGirl.create(:person, :with_hbx_staff_role)}

    it "should not have right navigation section" do
      render partial: 'broker_agencies/profiles/menu', locals: {active_tab: "home-tab" }
      expect(view.content_for(:horizontal_menu)).not_to include('multi-line')
    end

    context "with general agency disabled" do
      before :each do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
      end
      it "does not show general agency related links" do
        render partial: 'broker_agencies/profiles/menu', locals: {active_tab: "home-tab" }
        expect(view.content_for(:horizontal_menu)).not_to match /General Agencies/
      end
    end
  end

  context "with broker role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker"]) }
    let(:person) { FactoryGirl.create(:person, :with_broker_role) }

    context "with individual market enabled " do
      before do
        allow(view).to receive(:individual_market_is_enabled?).and_return(true)
      end

      it "should have include Medicaid application" do
        render partial: 'broker_agencies/profiles/menu', locals: {active_tab: "home-tab"}
        expect(view.content_for(:horizontal_menu)).to include('multi-line')
      end
    end

    context "with individual market disabled " do
      before do
        allow(view).to receive(:individual_market_is_enabled?).and_return(false)
      end

      it "should not include Medicaid application" do
        render partial: 'broker_agencies/profiles/menu', locals: {active_tab: "home-tab"}
        expect(view.content_for(:horizontal_menu)).to_not include('multi-line')
      end
    end


    context "with general agency disabled" do
      before :each do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
        render partial: 'broker_agencies/profiles/menu', locals: {active_tab: "home-tab" }
      end
      it "does not show general agency related links" do
        expect(view.content_for(:horizontal_menu)).not_to match /General Agencies/
      end
    end
  end
end
