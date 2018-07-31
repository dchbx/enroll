require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe InsuredEligibleForBenefitRule, :type => :model do
  let(:family) { double }
  let(:rule) { InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, family: family)}
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:consumer_role) { person.consumer_role }
  let(:benefit_package) {double}

  context "#is_benefit_categories_satisfied?" do
    it "should return true if benefit_package has both kinds of benefit categories" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health', 'dental'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, coverage_kind: 'dental', family: family)
      expect(rule.is_benefit_categories_satisfied?).to eq true
    end

    it "should return false if benefit package does not have the benefit categories with the current coverage kind" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, coverage_kind: 'dental', family: family)
      expect(rule.is_benefit_categories_satisfied?).to eq false
    end

    it "should return true if benefit package have the benefit categories with the current coverage kind" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
      expect(rule.is_benefit_categories_satisfied?).to eq true
    end
  end

  context "#is_age_range_satisfied?" do
    let(:consumer_role) {double(dob: (TimeKeeper.date_of_record - 20.years))}
    let(:benefit_package) {double}

    it "should return true when 0..0" do
      allow(benefit_package).to receive(:age_range).and_return (0..0)
      expect(rule.is_age_range_satisfied?).to eq true
    end

    it "should return true when in the age range" do
      allow(benefit_package).to receive(:age_range).and_return (0..30)
      expect(rule.is_age_range_satisfied?).to eq true
    end

    it "should return false when out of the age range" do
      allow(benefit_package).to receive(:age_range).and_return (0..10)
      expect(rule.is_age_range_satisfied?).to eq false
    end
  end

  context "is_age_range_satisfied_for_catastrophic?" do
    let(:consumer_role) {double(dob: (TimeKeeper.date_of_record - 20.years))}
    before do
      allow(consumer_role).to receive(:person).and_return(person)
    end

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
    let(:consumer_role) { (FactoryGirl.create(:person, :with_consumer_role, dob: (TimeKeeper.date_of_record - 20.years))).consumer_role}
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
    let(:consumer_role) { ConsumerRole.new}
    let(:tax_household) { double("TaxHousehold", current_csr_eligibility_kind: nil)}
    before :all do
      create_tax_household_for_mikes_family
      @consumer_role = mike.consumer_role
    end

    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:benefit_package_with_current_date_start_on) { FactoryGirl.build(:benefit_package) }

    it "should return true when csr_kind is blank" do
      allow(consumer_role).to receive(:latest_active_tax_household_with_year).and_return tax_household
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, family: family)
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return true when cost_sharing is blank" do
      allow(benefit_package_with_current_date_start_on).to receive(:start_on).and_return(TimeKeeper.date_of_record)
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package_with_current_date_start_on, family: mike.primary_family )
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return true when cost_sharing is equal to csr_kind" do
      benefit_package.benefit_eligibility_element_group.cost_sharing = 'csr_87'
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package, family: mike.primary_family)
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return false when cost_sharing is not equal to csr_kind" do
      benefit_package.benefit_eligibility_element_group.cost_sharing = 'csr_100'
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package, family: mike.primary_family)
      expect(rule.is_cost_sharing_satisfied?).to eq false
    end
  end

  context "is_residency_status_satisfied?" do
    let(:consumer_role) {double}
    let(:benefit_package) {double}

    it "return true if residency status include 'any'" do
      allow(benefit_package).to receive(:residency_status).and_return ["any", "other"]
      expect(rule.is_residency_status_satisfied?).to eq true
    end

    it "return false when consumer_role is nil" do
      allow(benefit_package).to receive(:residency_status).and_return ["other"]
      rule = InsuredEligibleForBenefitRule.new(nil, benefit_package, family: family)
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
        expect(rule.is_residency_status_satisfied?).to eq true
      end

      context "is not dc resident" do
        before :each do
          allow(person).to receive(:is_dc_resident?).and_return false
        end

        it "return true if any one's age >= 19 and is dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 20.years)
          allow(family_member).to receive(:is_dc_resident?).and_return true
          expect(rule.is_residency_status_satisfied?).to eq true
        end

        it "return false if all < 19" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 10.years)
          expect(rule.is_residency_status_satisfied?).to eq false
        end

        it "return false if all are not dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 20.years)
          allow(family_member).to receive(:is_dc_resident?).and_return false
          expect(rule.is_residency_status_satisfied?).to eq false
        end

        it "return false if all < 19 and all are not dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 10.years)
          allow(family_member).to receive(:is_dc_resident?).and_return false
          expect(rule.is_residency_status_satisfied?).to eq false

        end
      end

    end
  end

  context "is_family_relationships_satisfied?" do
    let(:rule) {InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)}

    it "should return true for relationship other than child" do
      allow(rule).to receive(:relation_ship_with_primary_applicant).and_return 'self'
      expect(rule.is_family_relationships_satisfied?).to eq true
    end

    it "should return true" do
      allow(rule).to receive(:relation_ship_with_primary_applicant).and_return 'child'
      allow(rule).to receive(:is_child_age_satisfied?).and_return true
      expect(rule.is_family_relationships_satisfied?).to eq true
    end

    it "should return false" do
      allow(rule).to receive(:relation_ship_with_primary_applicant).and_return 'child'
      allow(rule).to receive(:is_child_age_satisfied?).and_return false
      expect(rule.is_family_relationships_satisfied?).to eq false
    end
  end

  context "is_child_age_satisfied?" do
    let(:new_effective_on) {TimeKeeper.date_of_record}
    let(:rule) {InsuredEligibleForBenefitRule.new(consumer_role, benefit_package,new_effective_on:new_effective_on)}

    it "should return true when new_effective_on is before child crossed 26 years" do
      allow(rule).to receive(:relation_ship_with_primary_applicant).and_return 'child'
      allow(consumer_role).to receive(:dob).and_return TimeKeeper.date_of_record - 20.years
      expect(rule.is_child_age_satisfied?).to eq true
    end

    it "should return false when new_effective_on is after child entered 26 years" do
      allow(rule).to receive(:relation_ship_with_primary_applicant).and_return 'child'
      allow(consumer_role).to receive(:dob).and_return TimeKeeper.date_of_record - 30.years
      expect(rule.is_child_age_satisfied?).to eq false
    end
  end

  context "is_lawful_presence_status_satisfied?" do
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:benefit_eligibility_element_group) {FactoryGirl.build(:benefit_eligibility_element_group)}
    let(:rule) {InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, family: family)}

    before do
      allow(rule).to receive(:is_cost_sharing_satisfied?).and_return(true)
    end

    context "consumer_role aasm_state is fully_verified" do
      before :each do
        consumer_role.aasm_state = "fully_verified"
      end
      it "returns true for verification_successful state" do
        consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns true for verification_pending state" do
        consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns true for verification outstanding" do
        consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
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
        allow(rule).to receive(:is_citizenship_status_satisfied?).and_return(true)
        consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
        expect(rule.satisfied?).to eq [true, []]
      end
    end

    context "consumer_role aasm_state is NOT fully_verified" do
      before :each do
        consumer_role.aasm_state = "ssa_pending"
      end
      it "returns true for verification_successful state" do
        consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns true for verification_pending state" do
        consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns false for verification outstanding and event fired more than the outstanding verification window" do
        args = OpenStruct.new
        args.determined_at = TimeKeeper.date_of_record - ( Settings.aca.individual_market.verification_outstanding_window.days + 10.days)
        args.vlp_authority = "dhs"
        consumer_role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: args.determined_at, body: "payload"})
        consumer_role.ssn_invalid!(args)
        consumer_role.person.save!
        expect(rule.is_lawful_presence_status_satisfied?).to eq (Settings.aca.individual_market.verification_outstanding_window.days == 0)
      end

      it "returns true for verification outstanding and event fired less than the outstanding verification window" do
        args = OpenStruct.new
        args.determined_at = TimeKeeper.date_of_record - ( Settings.aca.individual_market.verification_outstanding_window.days - 10.days)
        args.vlp_authority = "dhs"
        consumer_role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: args.determined_at, body: "payload"})
        consumer_role.ssn_invalid!(args)
        consumer_role.person.save!
        expect(rule.is_lawful_presence_status_satisfied?).to eq true
      end

      it "returns false if insured_eligible_for_benefit_rule fails" do
        allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
        allow(rule).to receive(:is_family_relationships_satisfied?).and_return(true)
        allow(rule).to receive(:is_citizenship_status_satisfied?).and_return(true)
        consumer_role.person.created_at = TimeKeeper.date_of_record - ( Settings.aca.individual_market.verification_outstanding_window.days + 10.days)
        consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
        error_msg = (Settings.aca.individual_market.verification_outstanding_window.days == 0) ? [] : [["eligibility failed on lawful_presence_status"]]
        expect(rule.satisfied?).to eq [(Settings.aca.individual_market.verification_outstanding_window.days == 0), error_msg]
      end
    end

    context "is citizenship status satisfied?" do
      shared_examples_for "citizenship status satisfied" do |citizen_status, result|
        it "returns #{result} if citizen status is #{citizen_status}" do
          consumer_role.citizen_status = citizen_status
          expect(rule.is_citizenship_status_satisfied?).to eq result
        end
      end
      it_behaves_like "citizenship status satisfied", "not_lawfully_present_in_us", false
      it_behaves_like "citizenship status satisfied", "non_native_not_lawfully_present_in_us", false
      it_behaves_like "citizenship status satisfied", nil, false
      it_behaves_like "citizenship status satisfied", "alien_lawfully_present", true
      it_behaves_like "citizenship status satisfied", "", false
      it_behaves_like "citizenship status satisfied", " ", false
      it_behaves_like "citizenship status satisfied", "    ", false
    end

    context "#primary applicant" do
      let(:family) { FactoryGirl.build(:family, :with_primary_family_member_and_dependent)}
      it "should return family member record of primary applicant" do
        pa = family.family_members.where(is_primary_applicant: true).first
        expect(rule.send(:primary_applicant)).to eq pa
      end
    end

    context "#is_family_relationships_satisfied?" do
      let(:consumer_role) {FactoryGirl.create(:consumer_role, person: family.family_members.where(is_primary_applicant: false).first.person)}
      let(:consumer_role_two) {FactoryGirl.create(:consumer_role, person: person)}
      let(:rule) { InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, family: family) }
      let(:family) {
        family = FactoryGirl.build(:family, :with_primary_family_member_and_dependent, person: person)
        persn = family.family_members.where(is_primary_applicant: false).first.person
        persn.dob = person.dob
        persn.gender = person.gender
        persn.save
        family
       }
      let(:person) { FactoryGirl.create(:person)}
      before :each do
        person.person_relationships << PersonRelationship.new({
          :kind => 'child',
          :relative_id => family.family_members.where(is_primary_applicant: false).first.person.id
        })
      end

      context "if relationship is child" do
        it "should return true if age of child < 26" do
          allow(rule).to receive(:age_on_next_effective_date).with(consumer_role.dob).and_return 23
          expect(rule.is_family_relationships_satisfied?).to eq true
        end

        it "should return true if age of child = 26" do
          allow(rule).to receive(:age_on_next_effective_date).with(consumer_role.dob).and_return 26
          expect(rule.is_family_relationships_satisfied?).to eq true
        end

        it "should return false if age of child > 26" do
          allow(rule).to receive(:age_on_next_effective_date).with(consumer_role.dob).and_return 28
          expect(rule.is_family_relationships_satisfied?).to eq false
        end
      end

      context "if relationship is not child" do
        before do
          person.person_relationships.first.update_attribute(:kind, "spouse")
        end
        ages = [22, 26, 28]
        ages.each do |age|
          text = age == 26 ? "equal to" : (age > 26 ? "greater than" : "less than")
          it "should return true when age is #{text} 26" do
            allow(rule).to receive(:age_on_next_effective_date).with(consumer_role.dob).and_return "#{age}"
            expect(rule.is_family_relationships_satisfied?).to eq true
          end
        end
      end

      context "if person has two families one as primary & other as dependent" do
        let(:family_two) { FactoryGirl.build(:family, :with_primary_family_member, person: family.family_members.where(is_primary_applicant: false).first.person)}
        let(:rule2) { InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, family: family_two) }
        let(:rule3) { InsuredEligibleForBenefitRule.new(consumer_role_two, benefit_package, family: family) }

        it "should return true if person is primary applicant" do
          expect(rule3.is_family_relationships_satisfied?).to eq true
        end

        it "should return false if person is >26 and in child relation to primary" do
          expect(rule.is_family_relationships_satisfied?).to eq false
        end

        it "should return true if the same person now the primary applicant" do
          expect(rule2.is_family_relationships_satisfied?).to eq true
        end
      end
    end
  end

  context "rule satisfied?" do
    let(:consumer_role) {FactoryGirl.create(:consumer_role)}
    let(:benefit_package) {double}

    before :each do
      allow(consumer_role).to receive(:dob).and_return(TimeKeeper.date_of_record - 23.years)
      allow(benefit_package).to receive(:age_range).and_return((0..30))
      allow(benefit_package).to receive_message_chain('benefit_coverage_period.end_on').and_return(TimeKeeper.date_of_record + 100.days)
      allow(benefit_package).to receive_message_chain('benefit_eligibility_element_group.class.fields.keys').and_return([])
    end

    it "should return a false status if is_applying_coverage is false for the cosumer_role" do
      allow(consumer_role).to receive(:is_applying_coverage?).and_return(false)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, coverage_kind: 'health', family: family)
      status = rule.satisfied?.first
      expect(status).to eq false
    end

    it "should return a true status if is_applying_coverage is true for the cosumer_role" do
      allow(consumer_role).to receive(:is_applying_coverage?).and_return(true)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, coverage_kind: 'health', family: family)
      status = rule.satisfied?.first
      expect(status).to eq true
    end

  end
end
end
