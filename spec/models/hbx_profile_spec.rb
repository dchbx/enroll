require 'rails_helper'

RSpec.describe HbxProfile, :type => :model do
  let(:organization) { FactoryGirl.create(:organization) }

  let(:cms_id)  { "DC0" }
  let(:us_state_abbreviation)  { "DC" }
  let(:markets) { %w(shop unassisted_individual assisted_individual non_aca) }
  let(:valid_params) {
    {
      organization: organization,
      cms_id: cms_id,
      us_state_abbreviation: us_state_abbreviation
    }
  }

  context ".new" do
    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{HbxProfile.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with all required data" do
      let(:params)        { valid_params }
      let(:hbx_profile)   { HbxProfile.new(**params) }
      before :all do
        @hp_count = HbxProfile.all.size
      end

      it "should save" do
        expect(hbx_profile.save).to be_truthy
      end

      context "and it is saved" do
        let!(:hbx_profile) { FactoryGirl.create :hbx_profile }

        it "should return all HBX instances" do
          expect(HbxProfile.all.size).to eq @hp_count + 2
        end

        it "should be findable by ID" do
          expect(HbxProfile.find(hbx_profile._id)).to eq hbx_profile
        end
      end

      context ".search_random", dbclean: :after_each do
        let(:broker_agency_profile1) { FactoryGirl.create(:broker_agency_profile)}
        let(:broker_agency_profile2) { FactoryGirl.create(:broker_agency_profile)}

        before do
          DatabaseCleaner.clean
          broker_agency_profile1.organization.update_attributes(legal_name: "legal yo1")
          broker_agency_profile2.organization.update_attributes(legal_name: "legal yo2")
        end

        it "should return all the broker agencies profiles" do
          expect(HbxProfile.search_random(nil).size).to eq 2
          expect(HbxProfile.search_random(nil).first.class).to eq BrokerAgencyProfile
        end

        it "should return the  searched broker agency instances" do
          expect(HbxProfile.search_random(broker_agency_profile1.organization.legal_name).size).to eq 1
          expect(HbxProfile.search_random(broker_agency_profile1.organization.legal_name).first.class).to eq BrokerAgencyProfile
        end
      end
    end
  end
end
