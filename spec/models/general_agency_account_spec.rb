require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe GeneralAgencyAccount, type: :model do
  let(:employer_profile)      { FactoryGirl.create(:employer_profile)}
  let(:general_agency_profile) { FactoryGirl.build(:general_agency_profile) }
  let(:start_on)              { TimeKeeper.date_of_record }

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      general_agency_profile: general_agency_profile,
      start_on: start_on
    }
  end

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }
      let(:general_agency_account) {GeneralAgencyAccount.new(**params)}

      it "should be invalid" do
        expect(GeneralAgencyAccount.create(**params).valid?).to be_falsey
      end
    end

    context "with no start_on" do
      let(:params) {valid_params.except(:start_on)}

      it "should be invalid" do
        expect(GeneralAgencyAccount.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no general_agency_profile" do
      let(:params) {valid_params.except(:general_agency_profile)}

      it "should be invalid" do
        expect(GeneralAgencyAccount.create(**params).errors[:general_agency_profile_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:general_agency_account) { GeneralAgencyAccount.new(**params) }

      it "should save" do
        expect(general_agency_account.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_general_agency_account) do
          gaa = general_agency_account
          gaa.save!
          gaa
        end

        it "and should be findable by ID" do
          expect(GeneralAgencyAccount.find(saved_general_agency_account.id)._id).to eq saved_general_agency_account.id
        end
      end
    end
  end

  describe 'Instance method' do
    let(:general_agency_account) { FactoryGirl.build(:general_agency_account) }

    it "legal_name" do
      expect(general_agency_account.legal_name).to eq general_agency_account.general_agency_profile.try(:legal_name)
    end

    it "general_agency_profile" do
      general_agency_account.general_agency_profile = general_agency_profile
      expect(general_agency_account.general_agency_profile).to eq general_agency_profile
    end
  end

  describe 'Class method' do
    let(:broker_role1) { FactoryGirl.create(:broker_role) }
    let(:broker_role2) { FactoryGirl.create(:broker_role) }
    let(:gaa1) { FactoryGirl.create(:general_agency_account, broker_role_id: broker_role1.id) }
    let(:gaa2) { FactoryGirl.create(:general_agency_account, broker_role_id: broker_role2.id) }

    before :each do
      gaa1
      gaa2
    end

    it "all" do
      expect(GeneralAgencyAccount.all).to include gaa1
      expect(GeneralAgencyAccount.all).to include gaa2
    end

    it "find_by_broker_role_id" do
      expect(GeneralAgencyAccount.find_by_broker_role_id(broker_role1.id)).to include gaa1
      expect(GeneralAgencyAccount.find_by_broker_role_id(broker_role1.id)).not_to include gaa2
    end
  end
end
end
