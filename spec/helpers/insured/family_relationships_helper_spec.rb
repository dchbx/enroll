require "rails_helper"

RSpec.describe Insured::FamilyRelationshipsHelper, :type => :helper do
  describe "#calculate_age_by_dob" do
    context "return full name by id" do
      let(:person) {FactoryGirl.create(:person, first_name: "first", last_name: "last")}
      let(:test_family) {FactoryGirl.create(:family, :with_primary_family_member)}
      let(:child) {FactoryGirl.create(:family_member, :family => test_family, :person => person)}

      it "should return family member's full_name" do
        assign(:family, test_family)
        expect(helper.member_name_by_id(person.id)).to eq "first last"
      end

      it "should not return wrong full_name" do
        assign(:family, test_family)
        expect(helper.member_name_by_id(person.id)).not_to eq "dummy name"
      end
    end
  end
end
