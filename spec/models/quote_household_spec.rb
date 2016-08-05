require 'rails_helper'

RSpec.describe QuoteHousehold, type: :model do

  let(:quote){ create :quote ,:with_two_households_and_members }
  let(:quote_benefit_group_1){create :quote_benefit_group, title: "Group1" , quote: quote}
  let(:quote_benefit_group_2){create :quote_benefit_group, title: "Group2", quote: quote}

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

end
