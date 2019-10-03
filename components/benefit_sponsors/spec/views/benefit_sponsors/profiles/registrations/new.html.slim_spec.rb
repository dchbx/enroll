# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

RSpec.describe "benefit_sponsors/profiles/registrations/new", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let(:user) { FactoryBot.create(:user) }
  let(:agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: 'benefit_sponsor', portal: true) }

  before :each do
    current_benefit_market_catalog
    view.extend Pundit
    view.extend BenefitSponsors::Engine.routes.url_helpers
    @profile_type = 'benefit_sponsor'
    assign(:agency, agency)
    sign_in user
    render template: "benefit_sponsors/profiles/registrations/new"
  end

  it "should display county based on exchange" do
    if Settings.aca.address_query_county
      expect(rendered).to have_selector('label', text: 'County')
    else
      expect(rendered).to_not have_selector('label', text: 'County')
    end
  end

  it "should display referred by based on exchange" do
    if ApplicationHelperModStubber.display_referred_by_field_for_employer?
      expect(rendered).to have_content('Referred By *')
    else
      expect(rendered).to_not have_content('Referred By *')
    end
  end

  it "should display SIC code and tool tip based on exchange" do
    if ApplicationHelperModStubber.display_sic_field_for_employer?
      expect(rendered).to have_selector('#sicHelperToggle')
      expect(rendered).to have_selector('label', text: 'SIC Code *')
    else
      expect(rendered).to_not have_selector('#sicHelperToggle')
      expect(rendered).to_not have_selector('label', text: 'SIC Code *')
    end
  end
end
