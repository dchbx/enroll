require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/individuals/created.haml.erb", dbclean: :after_each do
  include AcapiVocabularySpecHelpers
  (1..15).to_a.each do |rnd|

    describe "given a generated individual, round #{rnd}" do
      include AcapiVocabularySpecHelpers

      before(:all) do
        download_vocabularies
      end

      let(:individual) { FactoryBot.create(:person) }
      let(:family) { FactoryBot.create(family, :with_primary_family_member, person: person) }

      before :each do
        render :template => "events/individuals/created", :locals => {:individual => individual}
      end

      it "should be schema valid" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end
    end

  end

  describe "given a person has broker role", dbclean: :after_each do

    let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,:with_site,:with_broker_agency_profile)}
    let!(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
    let!(:person_broker) {FactoryBot.create(:person,:with_work_email, :with_work_phone)}
    let!(:broker) {FactoryBot.create(:broker_role,aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person_broker)}

    before :each do
      render :template => "events/individuals/created", :locals => { :individual => person_broker}
      @doc = Nokogiri::XML(rendered)
    end

    it "should be schema valid" do
      expect(validate_with_schema(@doc)).to eq []
    end

    it "should have one broker role" do
      expect(@doc.xpath("//x:broker_roles/x:broker_role", "x" => "http://openhbx.org/api/terms/1.0").count).to eq 1
    end

    it "should have one office_location" do
      expect(@doc.xpath("//x:office_locations", "x" => "http://openhbx.org/api/terms/1.0").count).to eq 1
    end
  end
end
