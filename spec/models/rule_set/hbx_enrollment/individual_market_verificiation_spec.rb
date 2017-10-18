require "rails_helper"

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

  describe "determine the next state for non assisted Family" do
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

    context "enrollment with outstanding member" do
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

  describe "determine the next state for assisted Family" do

    before :each do
      allow_any_instance_of(Family).to receive(:application_applicable_year).and_return(TimeKeeper.date_of_record.year)
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
      faa_family.primary_applicant.person.consumer_role.assisted_verification_documents << [ 
        FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: income_assisted_verification.id),
        FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: mec_assisted_verification.id) ]
    end

    let(:person1) { FactoryGirl.create(:person, :with_consumer_role)}
    let(:faa_family) { FactoryGirl.create(:family, :with_primary_family_member, person: person1) }
    let(:application)  { FactoryGirl.create(:application, family: faa_family) }
    let(:applicant)  { FactoryGirl.create(:applicant, application: application) }
    let(:income_assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant) }
    let(:mec_assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant, verification_type: "MEC") }

    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
    let(:enrollment_status) { 'coverage_selected' }
    let(:enrollment)    { create(:hbx_enrollment, household: faa_family.latest_household,
                                                   effective_on: effective_on,
                                                   kind: "individual",
                                                   submitted_at: effective_on - 10.days,
                                                   aasm_state: enrollment_status
                                                   ) }


    context "hbx_enrollment with Income pending faa member" do
      it "should return move_to_pending! event" do
        income_assisted_verification.update_attributes(status: "pending")
        person1.consumer_role.update_attributes(assisted_income_validation: "pending")
        allow(subject).to receive(:roles_for_determination).and_return([person1.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_pending!
      end
    end

    context "hbx_enrollment with MEC pending faa member" do
      it "should return move_to_pending! event" do
        mec_assisted_verification.update_attributes(status: "pending")
        person1.consumer_role.update_attributes(assisted_mec_validation: "pending")
        allow(subject).to receive(:roles_for_determination).and_return([person1.consumer_role])
        expect(subject.determine_next_state).to eq :move_to_pending!
      end
    end
  end
end
