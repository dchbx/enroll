# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::Config::AcaHelper
end

RSpec.describe "benefit_sponsors/profiles/employers/employer_profiles/_show_profile", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:employer_profile) { abc_profile }
  let(:benefit_application) { initial_application }
  let(:benefit_group) { current_benefit_package }
  let(:census_employee1) { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee2) { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee3) { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
  let(:user) { FactoryBot.create(:user) }
  let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)}
  let(:reference_product) { current_benefit_package.sponsored_benefits[0].reference_product }

  before :each do
    view.extend Pundit
    view.extend BenefitSponsors::ApplicationHelper
    view.extend BenefitSponsors::Engine.routes.url_helpers
    view.extend Config::AcaHelper
    @employer_profile = employer_profile
    assign(:census_employees, [census_employee1, census_employee2, census_employee3])
    sign_in user
    allow(view).to receive(:benefit_sponsor_display_families_tab).and_return(false)
  end

  it "should display the dashboard content" do
    @tab = 'home'
    render template: "benefit_sponsors/profiles/employers/employer_profiles/show.html.erb"
    expect(rendered).to have_selector('h1', text: 'My Health Benefits Program')
  end

  it 'should display employer attestation table based on settings' do
    @tab = 'documents'
    render template: "benefit_sponsors/profiles/employers/employer_profiles/show.html.erb"
    if ApplicationHelperModStubber.employer_attestation_is_enabled?
      expect(rendered).to have_selector('h1', text: 'Verification of Employer Eligibility')
    else
      expect(rendered).not_to have_selector('h1', text: 'Verification of Employer Eligibility')
    end
  end

  # it "should display premium billing reports widget" do
  #   @tab = 'home'
  #   render template: "benefit_sponsors/profiles/employers/employer_profiles/show"
  #   expect(rendered).to have_selector('.panel-heading', text: 'Enrollment Report')
  # end
  #
  # it "shouldn't display premium billing reports widget" do
  #   @tab = 'home'
  #   allow(plan_year).to receive(:aasm_state).and_return("renewing_draft")
  #   render template: "benefit_sponsors/profiles/employers/employer_profiles/show"
  #   expect(rendered).to_not have_selector('h3', text: 'Enrollment Report')
  # end

  # it "should have active plan year but not display premium billings report" do
  #   # allow(benefit_application).to receive(:start_on).and_return(TimeKeeper.date_of_record + 3.years)
  #   allow(reference_product).to receive(:issuer_profile).and_return(issuer_profile)
  #   @tab = 'home'
  #   render template: "benefit_sponsors/profiles/employers/employer_profiles/show"
  #   y = TimeKeeper.date_of_record + 3.years
  #   year = y.year
  #   expect(rendered).to_not have_selector('h3', text: 'Enrollment Report')
  # end

end
