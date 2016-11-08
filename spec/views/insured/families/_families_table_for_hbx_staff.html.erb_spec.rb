require 'rails_helper'

RSpec.describe "insured/families/_families_table_for_hbx_staff.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:current_user) {FactoryGirl.create(:user, person: person)}
  let(:family) { double(is_eligible_to_enroll?: true) }
  let(:family1) { FactoryGirl.create(:family, :with_primary_family_member)}
  let(:families) { family1}
  before(:each) do
    
  end
  
  context "shows families" do

    before :each do
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: false, can_update_ssn?: true))
      sign_in(current_user)
    end

    it "should render the partial" do
      render partial: 'insured/families/families_table_for_hbx_staff', :collection => [[family1]] , as: :families
      expect(rendered).to match /Primary Applicant/
    end
    it "shows no roles, one family" do
      render partial: 'insured/families/families_table_for_hbx_staff', :collection => [[family1]] , as: :families
      expect(rendered).to match /<td>1.+<td>No.+<td>No.+<td>No/m
      expect(rendered).not_to match /<td>1.+<td>Yes.+<td>No.+<td>No/m
    end

    it "indicates consumer role"  do
      allow(family1.primary_applicant.person).to receive(:consumer_role).and_return(true)
      render partial: 'insured/families/families_table_for_hbx_staff', :collection => [[family1]] , as: :families
      expect(rendered).not_to match /<td>1.+<td>No.+<td>No.+<td>No/m
      expect(rendered).to match /<td>1.+<td>No.+<td>Yes.+<td>No/m
    end

    it "indicates employee roles"  do
      allow(family1.primary_applicant.person).to receive(:active_employee_roles).and_return(true)
      render partial: 'insured/families/families_table_for_hbx_staff', :collection => [[family1]] , as: :families
      expect(rendered).not_to match /<td>1.+<td>No.+<td>No.+<td>No/m
      expect(rendered).to match /<td>1.+<td>No.+<td>No.+<td>Yes/m
    end

    it "indicates both consumer role and employee roles"  do    
      allow(family1.primary_applicant.person).to receive(:consumer_role).and_return(true)
      allow(family1.primary_applicant.person).to receive(:active_employee_roles).and_return(true)
      render partial: 'insured/families/families_table_for_hbx_staff', :collection => [[family1]] , as: :families
      expect(rendered).not_to match /<td>1.+<td>No.+<td>No.+<td>No/m
      expect(rendered).to match /<td>1.+<td>No.+<td>Yes.+<td>Yes/m
    end

    it "the rendered partial should have an Edit DOB/SSN button" do
      render partial: 'insured/families/families_table_for_hbx_staff', :collection => [[family1]] , as: :families
      expect(response.body).to have_css("a", text: "Edit DOB/SSN")
    end

  end
end  