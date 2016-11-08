require 'rails_helper'

RSpec.describe "insured/families/_qle_detail.html.erb" do
  before :each do
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    render "insured/families/qle_detail"
  end

  it 'should have a hidden area' do
    expect(rendered).to have_selector('#qle-details.hidden')
  end

  it "should have qle form" do
    expect(rendered).to have_selector("form#qle_form")
  end

  it "should have qle date chose area" do
    expect(rendered).to have_selector("#qle-date-chose")
  end

  it "should have qle_message area" do
    expect(rendered).to have_selector("#qle_message")
  end

  it "should have success info" do
    expect(rendered).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time."
    expect(rendered).to have_selector(".success-info.hidden")
  end

  it "should have error message" do
    expect(rendered).to have_selector(".error-info.hidden")
    expect(rendered).to have_content "Based on the information you entered, you may be eligible for a special enrollment period. Please call us at #{Settings.contact_center.phone_number} to give us more information so we can see if you qualify."
  end

  it "should not have csr-form" do
    expect(rendered).not_to have_selector('.csr-form.hidden')
  end

  it "should have two qle-details-title" do
    expect(rendered).to have_selector(".qle-details-title", count: 2)
  end
end
