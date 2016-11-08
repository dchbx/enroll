require 'rails_helper'

describe "insured/families/verification/_verification.html.erb" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member) }

  before do
    assign :person, person
    assign :family, family
    assign :family_members, family.family_members
    allow_any_instance_of(Person).to receive(:primary_family).and_return family
    allow_any_instance_of(Person).to receive(:primary_family).and_return family
    allow(view).to receive(:unverified?).and_return false
    allow(view).to receive(:member_has_uploaded_docs).and_return false
    allow(view).to receive(:show_send_button_for_consumer?).and_return false
    allow(view).to receive(:verification_needed?).and_return true
    allow(view).to receive(:enrollment_group_unverified?).and_return true
    allow(view).to receive(:policy_helper).and_return(double("Policy", modify_admin_tabs?: true))
  end

  context "when user is consumer" do
    before :each do
      allow(view).to receive(:unverified?).and_return false
      allow(view).to receive(:verification_due_date).and_return (TimeKeeper.date_of_record)
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return false
      stub_template "insured/families/verification/_verification_docs_table.html.erb" => "content"
      render 'insured/families/verification/verification.html.erb'
    end
    it "should have Past Due label" do
      expect(rendered).to have_content "Past Due"
    end

    it "should have Documents FAQ list" do
      expect(rendered).to have_content "Documents FAQ"
    end
  end

  context "when user is admin" do
    before :each do
      allow(view).to receive(:all_family_members_verified).and_return true
      allow(view).to receive(:verification_due_date).and_return (TimeKeeper.date_of_record)
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return true
      stub_template "insured/families/verification/_verification_docs_table.html.erb" => "content"
      render 'insured/families/verification/verification.html.erb'
    end

    it "shows button for admin to complete verification for enrollment" do
      expect(rendered).to match /Complete Verification for Enrollment/
      expect(rendered).not_to match /Send documents for review/
    end
  end
end