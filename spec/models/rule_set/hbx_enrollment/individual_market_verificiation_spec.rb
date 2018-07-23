require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe RuleSet::HbxEnrollment::IndividualMarketVerification do
  subject { RuleSet::HbxEnrollment::IndividualMarketVerification.new(enrollment) }

  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:enrollment_status) { 'coverage_selected' }

  let(:family)        { create(:family, :with_primary_family_member) }
  let(:enrollment)    { create(:hbx_enrollment, household: family.latest_household,
                                                 effective_on: effective_on,
                                                 kind: "individual",
                                                 submitted_at: effective_on - 10.days,
                                                 aasm_state: enrollment_status
                                                 ) }

  describe "for a shop policy" do

    it "should not be applicable" do
      allow(enrollment).to receive(:benefit_sponsored?).and_return(true)
      expect(subject.applicable?).to eq false
    end
  end

  describe "for an inactive individual policy" do
    let(:enrollment_status) { 'shopping' }
  
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

  describe "determine the next state" do
    verification_states = %w(unverified ssa_pending dhs_pending verification_outstanding fully_verified verification_period_ended)
    verification_states.each do |state|
      obj=(state+"_person").to_sym
      let(obj) {
        person = FactoryGirl.create(:person, :with_consumer_role)
        person.consumer_role.aasm_state = state
        person
      }
    end

    context "assigns proper states for people" do
      verification_states.each do |status|
        it "#{status}_person has #{status} aasm_state" do
          expect(eval("#{status}_person").consumer_role.aasm_state).to eq status
        end
      end
    end

    context "enrollment with fully verified member and status contingent" do
      let(:enrollment_status) { 'enrolled_contingent' }

      it "return move_to_enrolled! event" do
        allow(subject).to receive(:roles_for_determination).and_return([fully_verified_person.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_enrolled!
      end
    end

    context "enrollment with fully verified member and status not pending/contingent" do
      let(:enrollment_status) { 'coverage_selected' }
      
      it 'should return do_nothing' do
        allow(subject).to receive(:roles_for_determination).and_return([fully_verified_person.consumer_role])
        expect(subject.determine_next_state).to eq :do_nothing
      end 
    end

    context "outstanding enrollment with outstanding member" do
      let(:enrollment_status) { 'enrolled_contingent' }
      it "return move_to_contingent! event" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_outstanding_person.consumer_role])
        expect(subject.determine_next_state).to eq :do_nothing
      end
    end

    context "selected enrollment with outstanding member" do
      let(:enrollment_status) { 'coverage_selected' }
      it "return move_to_contingent! event" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_outstanding_person.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_contingent!
      end
    end

    context "enrollment with verification_period_ended member" do
      it "return move_to_contingent! event" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_period_ended_person.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_contingent!
      end
    end

    context "enrollment with pending member" do
      it "return move_to_pending! event" do
        allow(subject).to receive(:roles_for_determination).and_return([ssa_pending_person.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_pending!
      end
    end

    context "enrollment with mixed and outstanding members" do
      it "return move_to_contingent! event" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_outstanding_person.consumer_role, fully_verified_person.consumer_role, ssa_pending_person.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_contingent!
      end
    end

    context "enrollment with mixed, NO outstanding, with pending members" do
      it "return move_to_pending! event" do
        allow(subject).to receive(:roles_for_determination).and_return([ssa_pending_person.consumer_role, fully_verified_person.consumer_role, dhs_pending_person.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_pending!
      end
    end
  end
end
end
