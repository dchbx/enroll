require 'rails_helper'

describe "insured/family_members/_dependent.html.erb", dbclean: :after_each do
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:person1) {FactoryBot.create(:person)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:dependent) { Forms::FamilyMember.new({id: BSON::ObjectId.new, family_id: family.id, first_name: person.first_name, last_name: person.last_name, relationship: 'child'}) }
  #let(:dependent) {FactoryBot.build(:family_member, family: family, is_primary_applicant: false, is_active: true, person: person1)}

  before :each do
    sign_in user
    allow(view).to receive(:edit_insured_family_member_path).and_return "#"
    allow(dependent).to receive(:age_on).with(TimeKeeper.date_of_record).and_return 10
  end

  it "should have name age gender relationship for dependent" do
    render "insured/family_members/dependent", dependent: dependent
    expect(rendered).to have_selector("label", text: 'NAME')
    expect(rendered).to have_selector("label", text: 'AGE')
    expect(rendered).to have_selector("label", text: 'GENDER')
    expect(rendered).to have_selector("label", text: 'RELATIONSHIP')
  end

end
