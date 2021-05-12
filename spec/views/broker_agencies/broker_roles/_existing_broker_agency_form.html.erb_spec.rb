require "rails_helper"

RSpec.describe "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb" do
  before :each do
    assign :broker_candidate, Forms::BrokerCandidate.new
  end

  it "should have search area" do
    render template: "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb"
    expect(rendered).to have_selector("input[placeholder='Name/FEIN']")
  end

  it "should have asterik for mandatory feilds" do
    render template: "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb"
    ["FIRST NAME", "LAST NAME", "DATE OF BIRTH", "EMAIL"].each do |item|
      expect(rendered).to have_selector("input[placeholder='#{item} *']")
    end
  end

  context "not staff" do
    before :each do
      assign :filter, "not_staff"
      render template: "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb"
    end

    it "should have asterik for mandatory feilds" do
      render template: "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb"
      ["FIRST NAME", "LAST NAME", "DATE OF BIRTH", "EMAIL", "NPN"].each do |item|
        expect(rendered).to have_selector("input[placeholder='#{item} *']")
      end
    end

    it "should have broker_agency_profile_fields area" do
      expect(rendered).to have_selector('div.broker-agency-info')
      expect(rendered).to have_selector('div.language_multi_select')
      expect(rendered).to have_selector('div.interaction-choice-control-broker-agency-accept-new-clients')
    end

    it "should have home address area" do
      expect(rendered).to have_selector('div.personal-info-row')
      expect(rendered).to have_content(/home address/i)
    end
  end
end
