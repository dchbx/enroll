require 'rails_helper'

RSpec.describe VerificationType, :type => :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }

  describe "verification_types creation" do
    it "creates types for person" do
      expect(person.verification_types.count).to be > 0
    end
  end

  describe "build certain type" do
    context "SSN" do
      it "doesn't have ssn type" do
        person.ssn = nil
        person.save
        expect(person.consumer_role.verification_types.by_name("Social Security Number").first).to be nil
      end
      it "builds ssn type" do
        expect(person.consumer_role.verification_types.by_name("Social Security Number").first).not_to be nil
      end
    end
    context "DC Residency" do
      it "builds DC Residency type" do
        expect(person.consumer_role.verification_types.by_name("DC Residency").first).not_to be nil
      end
    end
    context "American Indian Status" do
      it "build American Indian Status type" do
        person.tribal_id = "4848477"
        person.save
        expect(person.consumer_role.verification_types.by_name("American Indian Status").first).not_to be nil
      end
      it "doesn't build American Indian Status type" do
        person.tribal_id = nil
        person.save
        expect(person.consumer_role.verification_types.by_name("American Indian Status").first).to be nil
      end
    end
  end

  describe "type can be updated" do
    before do
      person.verification_types.each{|type| type.fail_type}
    end
    it "fail verification type" do
      expect(person.verification_types.all?{|type| type.is_type_outstanding?}).to be true
    end
    it "pass verification type" do
      person.verification_types.each{|type| type.pass_type}
      expect(person.verification_types.all?{|type| type.type_verified?}).to be true
    end
    it "pending verification type" do
      person.verification_types.each{|type| type.pending_type}
      expect(person.verification_types.all?{|type| type.validation_status == "pending"}).to be true
    end

    context 'DC Residency' do
      before do
        @residency_verification_type = person.verification_types.by_name('DC Residency').first
        @residency_verification_type.attest_type
        @history_track = @residency_verification_type.history_tracks.last
      end

      it 'attest verification type' do
        expect(@residency_verification_type.validation_status).to eq('attested')
      end

      it 'should update reason for verification type' do
        expect(@residency_verification_type.update_reason).to eq('Self Attest DC Residency')
      end

      it 'should add update_reason to history tracks' do
        expect(@history_track.modified.keys).to include('update_reason')
      end

      it 'should have update_reason as expected in history tracks' do
        expect(@history_track.modified['update_reason']).to eq('Self Attest DC Residency')
      end
    end
  end
end
