# frozen_string_literal: true

require "rails_helper"

RSpec.describe "benefit_sponsors/profiles/registrations/confirmation.html.erb", type: :view do

  before :each do
    view.extend BenefitSponsors::Engine.routes.url_helpers
    render template: "benefit_sponsors/profiles/registrations/confirmation.html.erb"
  end

  it "should have confirmation text" do
    expect(rendered).to have_content("We Received Your Broker Application")
  end

  it "should have see more links" do
    expect(rendered).to have_content("See More")
  end

  it "should have download button" do
    expect(rendered).to have_content("Download")
  end

  it "should have css" do
    expect(rendered).to have_css("#broker_confimation_panel")
  end

  it "should have input fields for email" do
    expect(rendered).to have_selector("input[placeholder='First Name *']")
    expect(rendered).to have_selector("input[placeholder='Last Name *']")
    expect(rendered).to have_selector("input[placeholder='Email *']")
  end
end