require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/brokers/created.xml.haml" do
  (1..15).to_a.each do |rnd|

    describe "given a generated individual, round #{rnd}" do
      include AcapiVocabularySpecHelpers

      before(:all) do
        download_vocabularies
      end

      let(:individual) { FactoryGirl.build_stubbed :generative_individual }

      before :each do
        allow(individual.broker_role).to receive(:latest_transition_time).and_return TimeKeeper.date_of_record
        render :template => "events/brokers/created", :locals => { :individual => individual}
      end

      it "should be schema valid" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end

      it "should include broker_payment_accounts" do
        expect(Nokogiri::XML(rendered).xpath("//x:broker_payment_accounts/x:broker_payment_account", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
        expect(Nokogiri::XML(rendered).xpath("//x:broker_payment_accounts/x:broker_payment_account/x:routing_number", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq individual.broker_role.broker_agency_profile.ach_routing_number
        expect(Nokogiri::XML(rendered).xpath("//x:broker_payment_accounts/x:broker_payment_account/x:account_number", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq individual.broker_role.broker_agency_profile.ach_account_number
      end

    end

  end
end
