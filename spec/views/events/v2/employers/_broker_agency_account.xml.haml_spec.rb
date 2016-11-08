require 'rails_helper'

RSpec.describe "app/views/events/v2/employers/_broker_agency_account.xml.haml" do

  describe "broker_agency_account xml" do
    let(:general_agency_account) {  FactoryGirl.create(:general_agency_account) }
    let(:broker_agency_account) { FactoryGirl.create(:broker_agency_account, {employer_profile:general_agency_account.employer_profile}) }

    context "ga_assignment" do
      context "no ga_assignment" do

        before :each do
          render :template => "events/v2/employers/_broker_agency_account.xml.haml", :locals => {:broker_agency_account => broker_agency_account}
          @doc = Nokogiri::XML(rendered)
        end

        it "should not have the general_agency_assignment" do
          expect(@doc.xpath("//broker_account/general_agency_assignment").count).to eq(0)
        end
      end

      context "with ga_assignment" do
        before :each do
          allow(general_agency_account).to receive(:for_broker_agency_account?).with(broker_agency_account).and_return(true)
          render :template => "events/v2/employers/_broker_agency_account.xml.haml",
                 locals: {broker_agency_account: broker_agency_account, employer_profile: general_agency_account.employer_profile}
          @doc = Nokogiri::XML(rendered)
        end

        it "should have the general_agency_assignment" do
          expect(@doc.xpath("//broker_account/ga_assignments/ga_assignment").count).to eq(1)
        end
      end
    end
  end
end