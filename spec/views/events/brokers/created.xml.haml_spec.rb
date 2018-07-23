require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/brokers/created.xml.haml" , dbclean: :after_each do

  describe "given a broker" , dbclean: :after_each do
    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    let!(:broker_agency_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization,:with_site,:with_broker_agency_profile)}
    let!(:broker_agency_profile) {broker_agency_organization.broker_agency_profile }
    let(:broker) {FactoryGirl.build(:broker_role,aasm_state:'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id)}
    let(:person_broker) {FactoryGirl.build(:person,:with_work_email, :with_work_phone, broker_role: broker)}

    before :each do
      broker_agency_profile.update_attributes(ach_routing_number:'123456789',ach_account_number:"9999999999999999")
      allow(person_broker.broker_role).to receive(:latest_transition_time).and_return TimeKeeper.date_of_record
      render :template => "events/brokers/created", :locals => { :individual => person_broker}
    end

    it "should be schema valid" do
      expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
    end

    it "should include broker_payment_accounts" do
      expect(Nokogiri::XML(rendered).xpath("//x:broker_payment_accounts/x:broker_payment_account", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
      expect(Nokogiri::XML(rendered).xpath("//x:broker_payment_accounts/x:broker_payment_account/x:routing_number", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq broker_agency_profile.ach_routing_number
      expect(Nokogiri::XML(rendered).xpath("//x:broker_payment_accounts/x:broker_payment_account/x:account_number", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq broker_agency_profile.ach_account_number
    end

  end
end
