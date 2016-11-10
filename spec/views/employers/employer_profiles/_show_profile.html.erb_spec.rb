require "rails_helper"

RSpec.describe "employers/employer_profiles/_show_profile" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee1) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:user) { FactoryGirl.create(:user) }
  before :each do
    @employer_profile = employer_profile
    stub_template "shared/alph_paginate" => ''
    assign(:census_employees, [census_employee1, census_employee2, census_employee3])
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true, list_enrollments?: nil))
    sign_in user
  end

  it "should display the Profile content" do
    @tab = 'profile'
    render template: "employers/employer_profiles/show_profile"
    expect(rendered).to match(/#{@employer_profile.legal_name}/)
    expect(rendered).to_not match(/Plan Year/)
    expect(rendered).to_not have_selector('#employees-list')
    expect(rendered).to_not have_selector('#broker_agency')
    expect(rendered).to_not have_selector('#families')
  end

  it "should display the Benefits content" do
    @tab = 'benefits'
    render template: "employers/employer_profiles/show_profile"
    expect(rendered).to match(/Plan Year/)
    expect(rendered).to_not have_selector('#employees-list')
    expect(rendered).to_not have_selector('#broker_agency')
    expect(rendered).to_not match(/#{@employer_profile.legal_name}/)
    expect(rendered).to_not have_selector('#families')
  end

  it "should display the Employees content" do
    @tab = 'employees'
    assign(:page_alphabets, ['a', 'b', 'c'])
    render template: "employers/employer_profiles/show_profile"
    expect(rendered).to_not have_selector('#broker_agency')
    expect(rendered).to_not match(/#{@employer_profile.legal_name}/)
    expect(rendered).to_not match(/Plan Year/)
    expect(rendered).to_not have_selector('#families')
  end

  it "should display the Broker Agency content" do
    @tab = 'broker_agency'
    stub_template "employers/broker_agency/_active_broker.html.erb" => ''
    render  template: "employers/employer_profiles/show_profile"
    expect(rendered).to_not match(/Plan Year/)
    expect(rendered).to_not have_selector('#families')
  end

  it "should display the Documents content" do
    @tab = 'documents'
    render template: "employers/employer_profiles/show_profile"
    expect(rendered).to match(/Documents/)
    expect(rendered).to_not have_selector('#broker_agency')
    expect(rendered).to_not match(/#{@employer_profile.legal_name}/)
    expect(rendered).to_not match(/Plan Year/)
    expect(rendered).to_not have_selector('#families')
  end

  it "should display the Families content" do
    @tab = 'families'
    @employees = []
    render template: "employers/employer_profiles/show_profile"
    expect(rendered).to_not match(/#{@employer_profile.legal_name}/)
    expect(rendered).to_not match(/Plan Year/)
    expect(rendered).to have_selector('#families')
  end

end
