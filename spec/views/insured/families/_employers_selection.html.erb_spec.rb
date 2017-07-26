require 'rails_helper'

RSpec.describe "insured/families/_employers_selection.html.erb" do
  let(:person) {FactoryGirl.build(:person)}
  let(:employee_role1) {FactoryGirl.build(:employee_role, person: person, employer_profile: ef1)}
  let(:employee_role2) {FactoryGirl.build(:employee_role, person: person, employer_profile: ef2)}
  let(:ef1) { FactoryGirl.build(:employer_profile) }
  let(:ef2) { FactoryGirl.build(:employer_profile) }
  let(:ce1) { FactoryGirl.build(:census_employee, employer_profile: ef1) }
  let(:ce2) { FactoryGirl.build(:census_employee, employer_profile: ef2) }

  before :each do
    allow(employee_role1).to receive(:census_employee).and_return ce1
    allow(employee_role2).to receive(:census_employee).and_return ce2
    allow(person).to receive(:active_employee_roles).and_return([employee_role1, employee_role2])
    assign(:person, person)
    assign(:employee_role, employee_role1)
    render "insured/families/employers_selection"
  end

  it "should have title" do
    expect(rendered).to have_content('Employers')
  end

  it "should get labels" do
    expect(rendered).to have_selector('div.n-radio-row')
  end

  it "should get legal_name of employer" do
    expect(rendered).to have_content(ef1.legal_name.capitalize)
    expect(rendered).to have_content(ef2.legal_name.capitalize)
  end

  it "should have form" do
    expect(rendered).not_to have_selector('form')
  end
end
