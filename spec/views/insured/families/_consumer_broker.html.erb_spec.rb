require 'rails_helper'

RSpec.describe "insured/families/_consumer_broker.html.erb" do
  #render 'consumer_broker', title: nil
  #@person.primary_family.current_broker_agency.broker_agency_profile.legal_name.capitalize



  let(:family1) { FactoryGirl.create(:family, :with_primary_family_member)}
  let(:broker_agency_account){FactoryGirl.create(:broker_agency_account,family:family1,is_active:true)}



  context "shows assignment date" do

    before :each do
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
    end

    it "should render the partial" do
      assign :person, family1.person
      assign :family, family1
      assign :broker_agency_account, broker_agency_account
      render partial: 'insured/families/consumer_broker.html.erb', locals: { title: nil}
      expect(rendered).to match /Your Broker/
    end
    it "the partial should have Assignment Date" do
      assign :person, family1.person
      assign :family, family1
      assign :broker_agency_account, broker_agency_account
      render partial: 'insured/families/consumer_broker.html.erb', locals: { title: nil}
      expect(rendered).to match /Assignment Date/
    end
  end
end