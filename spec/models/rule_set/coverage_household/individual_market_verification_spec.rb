require "rails_helper"

describe RuleSet::CoverageHousehold::IndividualMarketVerification do
  subject { RuleSet::CoverageHousehold::IndividualMarketVerification.new(coverage_household) }
  let(:coverage_household) { instance_double(CoverageHousehold, :active_individual_enrollments => active_individual_policies) }

  before :each do
    allow_any_instance_of(Family).to receive(:application_applicable_year).and_return(TimeKeeper.date_of_record.year)
  end

  describe "in a coverage household with no active individual policies" do
    let(:active_individual_policies) { [] } 
    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "in a coverage household with active individual policies" do
    let(:enrollment_members) { [] }
    let(:active_individual_policy) { 
      instance_double(HbxEnrollment, :hbx_enrollment_members => enrollment_members)
    }
    let(:active_individual_policies) { [active_individual_policy] } 

    it "should be applicable" do
      expect(subject.applicable?).to eq true
    end

    describe "in a coverage household with 2 members" do
      let(:person_1) { FactoryGirl.create(:person, :with_consumer_role)}
      let(:consumer_role_1) { person_1.consumer_role }
      let(:member_1) { 
        instance_double(HbxEnrollmentMember, :person => person_1)
      }

      let(:person_2) { FactoryGirl.create(:person, :with_consumer_role)}
      let(:consumer_role_2) { person_2.consumer_role }
      let(:member_2) { 
        instance_double(HbxEnrollmentMember, :person => person_2)
      }

      describe "where both of the members are enrolled" do
        describe "where one of the members is pending and the other has passed validation" do
          let(:enrollment_members) { [member_1, member_2] }
          before :each do
            allow(consumer_role_1).to receive(:ssa_pending?).and_return(false)
            allow(consumer_role_2).to receive(:ssa_pending?).and_return(true)
          end

          it "should recommend the unverified state" do
            expect(subject.determine_next_state).to eq(:move_to_pending!)
          end
        end

        describe "where one of the members is pending and the other has failed validation" do
          let(:enrollment_members) { [member_1, member_2] }
          before :each do
            allow(consumer_role_1).to receive(:ssa_pending?).and_return(true)
            allow(consumer_role_2).to receive(:ssa_pending?).and_return(false)
          end

          it "should recommend the unverified state" do
            expect(subject.determine_next_state).to eq(:move_to_pending!)
          end
        end

        describe "where one of the members is verified and the other has failed validation" do
          let(:enrollment_members) { [member_1, member_2] }

          before :each do
            allow(consumer_role_1).to receive(:ssa_pending?).and_return(false)
            allow(consumer_role_2).to receive(:ssa_pending?).and_return(false)
            allow(consumer_role_1).to receive(:dhs_pending?).and_return(false)
            allow(consumer_role_2).to receive(:dhs_pending?).and_return(false)
            allow(consumer_role_1).to receive(:verification_outstanding?).and_return(false)
            allow(consumer_role_2).to receive(:verification_outstanding?).and_return(true)
          end

          it "should recommend the enrolled_contingent state" do
            expect(subject.determine_next_state).to eq(:move_to_contingent!)
          end
        end
      end
    end
  end

  describe "coverage household for an assisted family" do

    before :each do
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
      family.primary_applicant.person.consumer_role.assisted_verification_documents << [ 
        FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: income_assisted_verification.id),
        FactoryGirl.build(:assisted_verification_document, application_id: application.id, applicant_id: applicant.id, assisted_verification_id: mec_assisted_verification.id) ]
      allow(coverage_household).to receive(:active_individual_enrollments).and_return([hbx_enrollment])
    end

    let!(:person) { FactoryGirl.create(:person, :with_consumer_role, first_name: "Assisted") }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:consumer_role) { person.consumer_role }
    let(:coverage_household) { family.active_household.coverage_households.first }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.households.first, coverage_household_id: coverage_household.id) }
    let(:application) { FactoryGirl.create(:application, family: family) }
    let(:applicant) { FactoryGirl.create(:applicant, application: application)}
    let(:income_assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant) }
    let(:mec_assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant, verification_type: "MEC") }

    context "hbx_enrollment with MEC pending faa member" do
      it "should return move_to_pending! event" do
        income_assisted_verification.update_attributes(status: "pending")
        consumer_role.update_attributes(assisted_income_validation: "pending")
        allow(subject).to receive(:roles_for_determination).and_return([consumer_role])
        expect(subject.determine_next_state).to eq :move_to_pending!
      end
    end

    context "hbx_enrollment with INCOME pending faa member" do
      it "should return move_to_pending! event" do
        mec_assisted_verification.update_attributes(status: "pending")
        consumer_role.update_attributes(assisted_mec_validation: "pending")
        allow(subject).to receive(:roles_for_determination).and_return([consumer_role])
        expect(subject.determine_next_state).to eq :move_to_pending!
      end
    end
  end
end
