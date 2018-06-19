require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/individuals/created.haml.erb" do
  (1..15).to_a.each do |rnd|

    describe "given a generated individual, round #{rnd}" do
      include AcapiVocabularySpecHelpers

      before(:all) do
        download_vocabularies
      end

      let(:individual) { FactoryGirl.build_stubbed :generative_individual }

      before :each do
        render :template => "events/individuals/created", :locals => { :individual => individual}
      end

      it "should be schema valid" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end
    end

  end
end
