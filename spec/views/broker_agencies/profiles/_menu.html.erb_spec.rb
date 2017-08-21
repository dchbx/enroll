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
  end

  context "with broker role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker"]) }
    let(:person) { FactoryGirl.create(:person, :with_broker_role) }

    it "should have right navigation section" do
      render partial: 'broker_agencies/profiles/menu', locals: {active_tab: "home-tab"}
      expect(view.content_for(:horizontal_menu)).to include('multi-line')
      expect(rendered).to_not have_text(/Brokers/)
    end
  end
end
