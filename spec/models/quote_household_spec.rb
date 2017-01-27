require 'rails_helper'

RSpec.describe QuoteHousehold, type: :model do

  let(:quote){ create :quote ,:with_two_households_and_members }
  let(:quote_benefit_group_1){create :quote_benefit_group, title: "Group1" , quote: quote}
  let(:quote_benefit_group_2){create :quote_benefit_group, title: "Group2", quote: quote}
  let(:quote_member_employee){build :quote_member, employee_relationship: "employee"}

  context "Validations" do
    it { is_expected.to validate_uniqueness_of(:family_id) }
  end


  context "Associations" do
    it { is_expected.to embed_many(:quote_members) }
    it { is_expected.to be_embedded_in(:quote) }
    it { is_expected.to accept_nested_attributes_for(:quote_members) }
  end

  context "BenefitGroups" do
    before do
      quote.quote_households[0].update("quote_benefit_group_id" => quote_benefit_group_1.id)
      quote.quote_households[1].update("quote_benefit_group_id" => quote_benefit_group_2.id)
    end

    it "should return household's BenefitGroups" do
      expect(quote.quote_households[0].quote_benefit_group.title).to eq "Group1"
      expect(quote.quote_households[1].quote_benefit_group.title).to eq "Group2"
    end
  end

  context "employee?" do
    it "should return true when employee is present" do
      quote.quote_households.first.quote_members << FactoryGirl.build(:quote_member, employee_relationship: "spouse")
      expect(quote.quote_households.first.spouse?).to be true
    end
  end

  context "children?" do
    it "should return true when child is present" do
      quote.quote_households.first.quote_members << FactoryGirl.build(:quote_member, employee_relationship: "child_under_26")
      expect(quote.quote_households.first.children?).to be true
    end
    it "should return false when there is no child" do
      expect(quote.quote_households.first.children?).to be false
    end
  end

  context "spouse?" do
    it "should return true when spouse is present" do
      quote.quote_households.first.quote_members << FactoryGirl.build(:quote_member, employee_relationship: "spouse")
      expect(quote.quote_households.first.spouse?).to be true
    end
    it "should return false when there is no spouse" do
      expect(quote.quote_households.first.spouse?).to be false
    end
  end

  context "employee" do
    it "should return employee" do
      quote.quote_households.first.quote_members= [quote_member_employee]
      expect(quote.quote_households.first.employee).to eq quote_member_employee
    end
  end

end