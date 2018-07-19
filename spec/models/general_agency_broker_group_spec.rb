require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe GeneralAgencyAccount, type: :model do
  let(:broker_agency_profile) { FactoryGirl.build(:broker_agency_profile) }

  let(:valid_params) do
    {
      broker_agency_profile: broker_agency_profile,
      name: 'test'
    }
  end

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }

      it "should be invalid" do
        expect(GeneralAgencyBrokerGroup.create(**params).valid?).to be_falsey
      end
    end

    context "with no name" do
      let(:params) {valid_params.except(:name)}

      it "should be invalid" do
        expect(GeneralAgencyBrokerGroup.create(**params).errors[:name].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:general_agency_broker_group) { GeneralAgencyBrokerGroup.new(**params) }

      it "should save" do
        expect(general_agency_broker_group.save).to be_truthy
      end
    end
  end
end
end
