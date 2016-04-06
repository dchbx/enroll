require "rails_helper"

describe RuleSet::HbxEnrollment::IndividualMarketVerification do
  subject { RuleSet::HbxEnrollment::IndividualMarketVerification.new(enrollment) }
  let(:enrollment) { instance_double(HbxEnrollment, :affected_by_verifications_made_today? => is_currently_active, :benefit_sponsored? => is_shop_enrollment, :plan_id => plan_id) }
  let(:is_currently_active) { true }
  let(:is_shop_enrollment) { false }
  let(:plan_id) { double }

  describe "for a shop policy" do
    let(:is_shop_enrollment) { true }

    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "for an inactive individual policy" do
    let(:is_currently_active) { false }

    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "for an active individual policy" do
    let(:enrollment_members) { [] }
    before(:each) do
      allow(enrollment).to receive(:hbx_enrollment_members).and_return(enrollment_members)
    end
    it "should be applicable" do
      expect(subject.applicable?).to eq true
    end

  end
end
