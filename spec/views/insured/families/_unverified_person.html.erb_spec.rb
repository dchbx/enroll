require 'rails_helper'

describe "insured/families/verification/_unverified_person.html.erb" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member) }

  before do
    allow_any_instance_of(Person).to receive(:primary_family).and_return family
    allow(view).to receive(:unverified?)
    allow(view).to receive(:text_center).and_return true
    allow(view).to receive(:show_v_type).and_return "in review"
    allow(view).to receive(:verification_type_class).and_return "info"
    allow(view).to receive(:verification_type_status).and_return "Verified"
    allow(view).to receive(:policy_helper).and_return(double("Family", updateable?: true))
    allow(view).to receive_message_chain("current_user.has_hbx_staff_role?")
    render :partial => 'insured/families/verification/unverified_person.html.erb', :locals => { :member => family.family_members.first}
  end

  context "verified" do
    before do
      allow(view).to receive(:unverified?).and_return false
    end

    it "shows verification type" do
      expect(rendered).to match /Immigration status/
    end

    it "shows verification type status" do
      expect(rendered).to match /label-info/
    end
  end

  context "unverified" do
    before do
      allow(view).to receive(:unverified?).and_return true
    end
    it "shows verification type" do
      expect(rendered).to match /Immigration status/
    end

    it "shows verification type status" do
      expect(rendered).to match /label-info/
    end
  end
end