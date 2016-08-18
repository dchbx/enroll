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

  context 'with an existing special enrollment period' do
    let(:current_user) { FactoryGirl.create :user, :with_family }

    let!(:sep) do
      current_user.primary_family.special_enrollment_periods[0] = FactoryGirl.build(:special_enrollment_period, effective_on_kind: ['first_of_next_month']).tap do |sep|
        current_user.primary_family.special_enrollment_periods.push sep
      end
    end

    before do
      sign_in current_user
      assign :existing_sep, sep
      render "insured/families/qle_detail"
    end

    it 'has a value for the input' do
      expect(rendered).to have_xpath("//input[@value='#{sep.qle_on.strftime('%m/%d/%Y')}']")
    end
  end
end
