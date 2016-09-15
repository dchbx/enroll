require 'rails_helper'

RSpec.describe QuoteMember, type: :model do
  let(:quote_member){build_stubbed :quote_member}
  context "Validations" do
    it { is_expected.to validate_presence_of(:dob) }
    it { is_expected.to validate_inclusion_of(:employee_relationship).to_allow(QuoteMember::EMPLOYEE_RELATIONSHIP_KINDS) }
  end

  context "#age_on" do 
    it "should return age on a given date" do
      expect(quote_member.age_on(Date.parse("01/01/2001"))).to eq 14
    end
  end

end
