require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?

describe "A new consumer role with an individual market enrollment", :dbclean => :around_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:family) { FactoryGirl.create(:individual_market_family, primary_person: person) }
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:enrollment) do
    benefit_sponsorship = hbx_profile.benefit_sponsorship
    benefit_package = benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first
    plan = Plan.find(benefit_package.benefit_ids.first)
    enrollment = family.households.first.create_hbx_enrollment_from(
      coverage_household: family.households.first.coverage_households.first,
      consumer_role: person.consumer_role,
      benefit_package: hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first
    )
    enrollment.plan = plan
    enrollment.select_coverage!
    enrollment
  end

  describe "when lawful presence fails verification" do
    let(:denial_information) do
      Struct.new(:determined_at, :vlp_authority).new(Time.now, "ssa")
    end

    before :each do
      person.consumer_role.coverage_purchased!("args")
    end

    describe "when the enrollment is active" do
      before :each do
        enrollment
        person.consumer_role.ssn_invalid!(denial_information)
      end

      it "puts the enrollment in enrolled_contingent state" do
          enroll = HbxEnrollment.by_hbx_id(enrollment.hbx_id).first
          expect(enroll.aasm_state).to eql "enrolled_contingent"
      end
    end

    describe "when the enrollment is terminated" do
      before :each do
        enrollment.terminate_coverage!
        person.consumer_role.ssn_invalid!(denial_information)
      end

      it "does not change the state of the enrollment" do
          enroll = HbxEnrollment.by_hbx_id(enrollment.hbx_id).first
          expect(enroll.aasm_state).to eql "coverage_terminated"
      end
    end
  end
end

end
