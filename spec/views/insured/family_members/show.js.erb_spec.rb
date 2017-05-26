require 'rails_helper'

describe "insured/family_members/show.js.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }

  context "render show by creat" do
    before :each do
      sign_in user
      assign(:person, person)
      assign(:created, true)
      allow(FamilyMember).to receive(:find).with(family_member.id).and_return(family_member)
      allow(family_member).to receive(:primary_relationship).and_return("self")
      allow(family_member).to receive(:person).and_return person
      allow(person).to receive(:has_mailing_address?).and_return false
      assign(:dependent, Forms::FamilyMember.find(family_member.id))
      @request.env['HTTP_REFERER'] = 'consumer_role_id'

      stub_template "insured/family_members/dependent" => ''
      render file: "insured/family_members/show.js.erb"
    end

    it "should display notice" do
      expect(rendered).to match /qle_flow_info/
      expect(rendered).to match /removeClass/
      expect(rendered).to match /hidden/
    end
  end
end
