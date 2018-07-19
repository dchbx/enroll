require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe RuleSet::CoverageHousehold::IndividualMarketVerification do
  subject { RuleSet::CoverageHousehold::IndividualMarketVerification.new(coverage_household) }
  let(:coverage_household) { instance_double(CoverageHousehold, :active_individual_enrollments => active_individual_policies) }

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
        let(:consumer_role_1) { instance_double(ConsumerRole) }
        let(:person_1) { instance_double(Person, :consumer_role => consumer_role_1) }
        let(:member_1) { 
          instance_double(HbxEnrollmentMember, :person => person_1)
        }
        let(:consumer_role_2) { instance_double(ConsumerRole) }
        let(:person_2) { instance_double(Person, :consumer_role => consumer_role_2) }
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

end
end
