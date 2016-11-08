require 'rails_helper'

RSpec.describe "insured/families/_employer_panel.html.erb" do
  let(:person) {FactoryGirl.build(:person)}
  let(:employee_role) {FactoryGirl.build(:employee_role)}
  let(:employer_profile) {FactoryGirl.build(:employer_profile)}

  before :each do
    assign(:person, person)
    assign(:employee_role, employee_role)
    allow(view).to receive(:is_under_open_enrollment?).and_return true
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
    render "insured/families/employer_panel"
  end

  it "should have carousel-qles area" do
    expect(rendered).to have_selector('div.alert-notice')
  end

  it "should have close link" do
    expect(rendered).to have_selector('a.close')
  end

  it "should have employer name" do
    allow(employee_role).to receive(:employer_profile).and_return employer_profile
    expect(rendered).to have_selector('input')
    expect(rendered).to have_content("Congratulations on your new job at #{employer_profile.legal_name}.")
  end
end
