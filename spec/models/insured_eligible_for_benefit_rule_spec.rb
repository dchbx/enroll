require 'rails_helper'

RSpec.describe InsuredEligibleForBenefitRule, :type => :model do
  context "#is_benefit_categories_satisfied?" do
    let(:consumer_role) {double}
    let(:benefit_package) {double}

    it "should return true" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health', 'dental'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, 'dental')
      expect(rule.is_benefit_categories_satisfied?).to eq true
    end

    it "should return false" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, 'dental')
      expect(rule.is_benefit_categories_satisfied?).to eq false
    end

    it "coverage_kind" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_benefit_categories_satisfied?).to eq true
    end
  end

  context "#is_age_range_satisfied?" do
    let(:consumer_role) {double(dob: (TimeKeeper.date_of_record - 20.years))}
    let(:benefit_package) {double}

    it "should return true when 0..0" do
      allow(benefit_package).to receive(:age_range).and_return (0..0)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied?).to eq true
    end

    it "should return true when in the age range" do
      allow(benefit_package).to receive(:age_range).and_return (0..30)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied?).to eq true
    end

    it "should return false when out of the age range" do
      allow(benefit_package).to receive(:age_range).and_return (0..10)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied?).to eq false
    end
  end

  context "is_age_range_satisfied_for_catastrophic?" do
    let(:consumer_role) {double(dob: (TimeKeeper.date_of_record - 20.years))}
    let(:benefit_package) {double}

    it "should return true when not catastrophic" do
      allow(benefit_package).to receive(:age_range).and_return (0..0)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied_for_catastrophic?).to eq true
    end

    context "when benefit_package is catastrophic" do
      before :each do
        allow(benefit_package).to receive(:age_range).and_return (0..30)
      end

      it "should return true when in the age range" do
        allow(benefit_package).to receive(:benefit_coverage_period).and_return(double(end_on: TimeKeeper.date_of_record))
        rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
        expect(rule.is_age_range_satisfied_for_catastrophic?).to eq true
      end

      it "should return false when out of the age range" do
        allow(benefit_package).to receive(:benefit_coverage_period).and_return(double(end_on: (TimeKeeper.date_of_record + 20.years)))
        rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
        expect(rule.is_age_range_satisfied_for_catastrophic?).to eq false
      end
    end
  end

  context "age_on_benefit_end_on" do
    let(:consumer_role) {double(dob: (TimeKeeper.date_of_record - 20.years))}
    let(:benefit_package) {double}
    let(:rule) { InsuredEligibleForBenefitRule.new(consumer_role, benefit_package) }
    let(:end_on) { Date.new(2016, 12, 31) }

    context "should return 31" do
      it "dob is 1985-12-31" do
        dob = Date.new(1985, 12, 31)
        expect(rule.age_on_benefit_end_on(dob, end_on)).to eq 31
      end

      it "dob is 1985-7-12" do
        dob = Date.new(1985, 7, 12)
        expect(rule.age_on_benefit_end_on(dob, end_on)).to eq 31
      end
    end

    context "should return 30" do
      it "dob is 1986-1-1" do
        dob = Date.new(1986, 1, 1)
        expect(rule.age_on_benefit_end_on(dob, end_on)).to eq 30
      end

      it "dob is 1985-2-1" do
        dob = Date.new(1986, 2, 1)
        expect(rule.age_on_benefit_end_on(dob, end_on)).to eq 30
      end

      it "dob is 1985-2-2" do
        dob = Date.new(1986, 2, 2)
        expect(rule.age_on_benefit_end_on(dob, end_on)).to eq 30
      end

      it "dob is 1985-12-31" do
        dob = Date.new(1986, 12, 31)
        expect(rule.age_on_benefit_end_on(dob, end_on)).to eq 30
      end
    end
  end

  context "is_cost_sharing_satisfied?" do
    include_context "BradyBunchAfterAll"
    before :all do
      create_tax_household_for_mikes_family
      @consumer_role = mike.consumer_role
    end

    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:benefit_package_with_current_date_start_on) { FactoryGirl.build(:benefit_package) }

    it "should return true when csr_kind is blank" do
      rule = InsuredEligibleForBenefitRule.new(ConsumerRole.new, benefit_package)
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return true when cost_sharing is blank" do
      allow(benefit_package_with_current_date_start_on).to receive(:start_on).and_return(TimeKeeper.date_of_record)
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package_with_current_date_start_on )
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return true when cost_sharing is equal to csr_kind" do
      benefit_package.benefit_eligibility_element_group.cost_sharing = 'csr_87'
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package)
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return false when cost_sharing is not equal to csr_kind" do
      benefit_package.benefit_eligibility_element_group.cost_sharing = 'csr_100'
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package)
      expect(rule.is_cost_sharing_satisfied?).to eq false
    end
  end

  context "is_residency_status_satisfied?" do
    let(:consumer_role) {double}
    let(:benefit_package) {double}

    it "return true if residency status include 'any'" do
      allow(benefit_package).to receive(:residency_status).and_return ["any", "other"]
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_residency_status_satisfied?).to eq true
    end

    it "return false when consumer_role is nil" do
      allow(benefit_package).to receive(:residency_status).and_return ["other"]
      rule = InsuredEligibleForBenefitRule.new(nil, benefit_package)
      expect(rule.is_residency_status_satisfied?).to eq false
    end

    describe "include state_resident" do
      let(:family_member) {double}
      let(:family) {double(family_members: double(active: [family_member]))}
      let(:person) {double(families: [family])}
      let(:consumer_role) {double(person: person)}
      let(:benefit_package) {double}

      before :each do
        allow(benefit_package).to receive(:residency_status).and_return ["state_resident", "other"]
      end

      it "return true if is dc resident" do
        allow(person).to receive(:is_dc_resident?).and_return true
        rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
        expect(rule.is_residency_status_satisfied?).to eq true
      end

      context "is not dc resident" do
        before :each do
          allow(person).to receive(:is_dc_resident?).and_return false
        end

        it "return true if any one's age >= 19 and is dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 20.years)
          allow(family_member).to receive(:is_dc_resident?).and_return true
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq true
        end

        it "return false if all < 19" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 10.years)
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq false
        end

        it "return false if all are not dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 20.years)
          allow(family_member).to receive(:is_dc_resident?).and_return false
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq false
        end

        it "return false if all < 19 and all are not dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 10.years)
          allow(family_member).to receive(:is_dc_resident?).and_return false
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq false

        end
      end

    end
  end

  context "is_lawful_presence_status_satisfied?" do
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:benefit_eligibility_element_group) {FactoryGirl.build(:benefit_eligibility_element_group)}
    let(:role) {FactoryGirl.create(:consumer_role_object)}
    let(:rule) {InsuredEligibleForBenefitRule.new(role, benefit_package)}
    let(:person) {double}

    context "consumer_role aasm_state is fully_verified" do
      before :each do
        role.aasm_state = "fully_verified"
      end
      it "returns true for verification_successful state" do
        role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns true for verification_pending state" do
        role.lawful_presence_determination.aasm_state = "verification_pending"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns true for verification outstanding" do
        role.lawful_presence_determination.aasm_state = "verification_outstanding"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns array with benefit_eligibility_element_group fields" do
        array = ["_id", "market_places", "enrollment_periods", "family_relationships",
                 "benefit_categories", "incarceration_status", "age_range", "citizenship_status",
                 "residency_status", "ethnicity", "cost_sharing", "lawful_presence_status"]
        expect(benefit_package.benefit_eligibility_element_group.class.fields.keys).to eq array
      end

      it "returns true if insured_eligible_for_benefit_rule satisfies all criteria" do
        allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
        allow(rule).to receive(:is_family_relationships_satisfied?).and_return(true)
        role.lawful_presence_determination.aasm_state = "verification_outstanding"
        expect(rule.satisfied?).to eq [true, []]
      end
    end

    context "consumer_role aasm_state is NOT fully_verified" do
      before :each do
        role.aasm_state = "ssa_pending"
      end
      it "returns true for verification_successful state" do
        role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns true for verification_pending state" do
        role.lawful_presence_determination.aasm_state = "verification_pending"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns false for verification outstanding and event fired more than the outstanding verification window" do
        args = OpenStruct.new
        args.determined_at = TimeKeeper.date_of_record - ( Settings.aca.individual_market.verification_outstanding_window.days + 10.days)
        args.vlp_authority = "dhs"
        role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: args.determined_at, body: "payload"})
        role.ssn_invalid!(args)
        role.person.save!
        expect(rule.is_lawful_presence_status_satisfied?).to eq (Settings.aca.individual_market.verification_outstanding_window.days == 0)
      end

      it "returns true for verification outstanding and event fired less than the outstanding verification window" do
        args = OpenStruct.new
        args.determined_at = TimeKeeper.date_of_record - ( Settings.aca.individual_market.verification_outstanding_window.days - 10.days)
        args.vlp_authority = "dhs"
        role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: args.determined_at, body: "payload"})
        role.ssn_invalid!(args)
        role.person.save!
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns false if insured_eligible_for_benefit_rule fails" do
        allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
        allow(rule).to receive(:is_family_relationships_satisfied?).and_return(true)
        role.person.created_at = TimeKeeper.date_of_record - ( Settings.aca.individual_market.verification_outstanding_window.days + 10.days)
        role.lawful_presence_determination.aasm_state = "verification_outstanding"
        error_msg = (Settings.aca.individual_market.verification_outstanding_window.days == 0) ? [] : [["eligibility failed on lawful_presence_status"]]
        expect(rule.satisfied?).to eq [(Settings.aca.individual_market.verification_outstanding_window.days == 0), error_msg]
      end
    end

    context "is citizenship status satisfied" do
      it "returns false if person is not lawfully present" do
        role.citizen_status = "not_lawfully_present_in_us"
        expect(rule.is_citizenship_status_satisfied?).to eq false
      end

      it "returns true if person is lawfully present" do
        role.citizen_status = "alien_lawfully_present"
        expect(rule.is_citizenship_status_satisfied?).to eq true
      end
    end
  end
end
