require 'rails_helper'

describe CoverageHousehold, type: :model do
  context "family_members" do
    let(:coverage_household) {CoverageHousehold.new}
    let(:family) {Family.new}
    let(:family_member1) {FactoryGirl.build_stubbed(:family_member, is_active: true)}
    let(:family_member2) {FactoryGirl.build_stubbed(:family_member, is_active: false)}
    let(:family_members) {[family_member1, family_member2]}

    it "should return blank array" do
      allow(coverage_household).to receive(:family).and_return(nil)
      expect(coverage_household.family_members).to eq []
    end

    it "should return active_family_members" do
      allow(coverage_household).to receive(:family).and_return(family)
      family.family_members << family_member1
      family.family_members << family_member2
      expect(coverage_household.family_members).to eq [family_member1]
    end
  end
end

describe CoverageHousehold, "when informed that eligiblity has changed for an individual" do
  let(:mock_person) { double }
  let(:mock_consumer_role) { double(person: mock_person) }
  let(:matching_coverage_household) { instance_double("CoverageHousehold") }
  let(:matching_hbx_enrollment) { instance_double("HbxEnrollment") }
  let(:hbxs) { [matching_hbx_enrollment] }
  let(:mock_household) { instance_double("Household", :coverage_households => [matching_coverage_household], hbx_enrollments: hbxs) }
  let(:mock_family) { instance_double("Family", :households => [mock_household]) }

  before :each do
    allow(Family).to receive(:find_all_by_person).with(mock_person).and_return([mock_family])
  end

  it "should locate and notify each coverage household containing that individual" do
    expect(matching_coverage_household).to receive(:evaluate_individual_market_eligiblity)
    expect(matching_hbx_enrollment).to receive(:evaluate_individual_market_eligiblity)
    CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
  end

  describe "and that individual exists on individual market policies" do
    let(:matching_coverage_household) { CoverageHousehold.new }
    let(:mock_ruleset) { instance_double(::RuleSet::CoverageHousehold::IndividualMarketVerification, :applicable? => true, :determine_next_state => recommended_event) }

    before :each do
      allow(::RuleSet::CoverageHousehold::IndividualMarketVerification).to receive(:new).with(matching_coverage_household).and_return(mock_ruleset)
      allow(matching_hbx_enrollment).to receive(:evaluate_individual_market_eligiblity).and_return(true)
    end

    describe "with a ruleset recommending contingent status" do
      let(:recommended_event) { :move_to_contingent! }
      it "should update it's state to match the state provided by the ruleset" do
        expect(matching_coverage_household).to receive(recommended_event)
        CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
      end
    end

    describe "with a ruleset recommending pending status" do
      let(:recommended_event) { :move_to_pending! }
      it "should update it's state to match the state provided by the ruleset" do
        expect(matching_coverage_household).to receive(recommended_event)
        CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
      end
    end

    describe "with a ruleset recommending enrolled status" do
      let(:recommended_event) { :move_to_enrolled! }
      it "should update it's state to match the state provided by the ruleset" do
        expect(matching_coverage_household).to receive(recommended_event)
        CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
      end
    end
  end
end
