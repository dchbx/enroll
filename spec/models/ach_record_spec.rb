require 'rails_helper'

RSpec.describe AchRecord, :type => :model do
  let(:bank_name) { "M&T Bank"}
  let(:routing_number) { "123456789" }
  let(:params) { { routing_number: routing_number, bank_name: bank_name} }

  describe ".new" do
    context "with valid params" do

      it "should be a valid record" do
        expect(AchRecord.new(params)).to be_valid
      end
    end

    context "with a routing number of incorrect length" do

      context "that is too long" do
        let(:routing_number) { "12345667890" }

        it "should not be valid" do
          expect(AchRecord.new(params)).to_not be_valid
        end
      end

      context "that is too short" do
        let(:routing_number) { "12345667" }

        it "should not be valid" do
          expect(AchRecord.new(params)).to_not be_valid
        end
      end
    end

    context "with non unique values" do
      let!(:existing_record) { create(:ach_record, routing_number: routing_number, bank_name: bank_name) }

      it "should enforce uniqueness" do
        expect(AchRecord.new(params)).to_not be_valid
      end
    end

    context "with non matching routing number confirmation" do
      it "should not be valid" do
        expect(AchRecord.new(params.merge(routing_number_confirmation: '987654321'))).to_not be_valid
      end

      it "is valid without the confirmation included" do
        expect(AchRecord.new(params)).to_not be_valid
      end
    end
  end

end
