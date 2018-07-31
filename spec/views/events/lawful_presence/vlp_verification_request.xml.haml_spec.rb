require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe "events/lawful_presence/vlp_verification_request.xml.haml"
(1..15).to_a.each do |rnd|

  describe "given a generated individual, round #{rnd}" do
    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    let(:individual) { FactoryGirl.build_stubbed :generative_individual }

    before :each do
      render :template => "events//lawful_presence/vlp_verification_request.xml", :locals => { :individual => individual, :coverage_start_date => Date.today }
    end

    it "should be schema valid" do
      expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
    end

  end

end
end
