require 'rails_helper'

describe "exchanges/hbx_profiles/_edit_enrollment.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }

  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:enrollment) { FactoryGirl.create(:hbx_enrollment,
                                      household: family.active_household,
                                      kind: "employer_sponsored",
                                      submitted_at: TimeKeeper.datetime_of_record - 3.days,
                                      created_at: TimeKeeper.datetime_of_record - 3.days
                              )}

  let(:new_dob) { 66.years.ago.to_date }
  let(:new_ssn) { '675498744' }

  let(:with_premium_implications)     { {enrollment.id => true} }
  let(:without_premium_implications)  { {} }

  let(:premium_implication_mesage)    { "Active enrollment(s) for this person exists. Updating DOB has implications as 
                                         it could result in the change of premium for the following enrollment\(s\)" }

  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return true
    allow(person).to receive(:primary_family).and_return(family)
    sign_in(user)
    assign(:person, person)
  end

  it "display premium implications message if there exists any enrollment that is affected by DOB change" do
    assign(:premium_implications, with_premium_implications)
    render template: "exchanges/hbx_profiles/_edit_enrollment.html.erb"
    expect(rendered).to have_text(premium_implication_mesage)
  end

  it "Do NOT display premium implications message if there is no enrollment affected by DOB change" do
    assign(:premium_implications, without_premium_implications)
    render template: "exchanges/hbx_profiles/_edit_enrollment.html.erb"
    expect(rendered).to_not have_text(premium_implication_mesage)
  end
end    

