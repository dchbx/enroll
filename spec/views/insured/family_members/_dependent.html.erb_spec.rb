require 'rails_helper'

describe "insured/family_members/_dependent.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:person1) {FactoryGirl.create(:person)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:dependent) {FactoryGirl.build(:family_member, family: family, is_primary_applicant: false, is_active: true, person: person1)}

  before :each do
    sign_in user
    allow(view).to receive(:edit_insured_family_member_path).and_return "#"
  end

  it "should have name age gender relationship for dependent" do
    render "insured/family_members/dependent", dependent: dependent, person: person1
    expect(rendered).to have_selector("label", text: 'NAME')
    expect(rendered).to have_selector("label", text: 'AGE')
    expect(rendered).to have_selector("label", text: 'GENDER')
    expect(rendered).to have_selector("label", text: 'RELATIONSHIP')
  end

end
