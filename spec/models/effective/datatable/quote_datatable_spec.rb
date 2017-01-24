require 'rails_helper'

describe Effective::Datatables::QuoteDatatable do

  def quote_datatable quote
    quote.broker_role_id=broker_role.id
    quote.save
    Effective::Datatables::QuoteDatatable.broker_role_id = broker_role.id
    quote_table = Effective::Datatables::QuoteDatatable.new
  end

  context "draft_quote_publish_disabled?" do
    context "for draft quotes " do
      let(:broker_role) { FactoryGirl.create(:broker_role) }
      let(:quote) { FactoryGirl.create(:quote) }
      let(:with_household_and_members) { FactoryGirl.create(:quote, :with_household_and_members) }
      let(:with_two_households_and_members) { FactoryGirl.create(:quote, :with_two_households_and_members)}
     
      it "should return disabled if View Published Quote is disable for draft quote" do
        quote.aasm_state = "draft"
        quote.save
        expect(subject.draft_quote_publish_disabled?(quote)).to eq 'disabled'
      end
    end
  end
end
