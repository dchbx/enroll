require 'rails_helper'

describe CoverageHousehold, type: :model do
  let!(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let!(:person2) { FactoryGirl.create(:person)}
  let!(:family) {
        family = FactoryGirl.create(:family, :with_primary_family_member, person: person)
        FactoryGirl.create(:family_member, family: family, is_active: false, person: person2)
        person.person_relationships.create(successor_id: person2.id, predecessor_id: person.id, kind: "spouse", family_id: family.id)
        person2.person_relationships.create(successor_id: person.id, predecessor_id: person2.id, kind: "spouse", family_id: family.id)
        person.save!
        person2.save!
        family.save!
        family
    }
  let(:consumer_role) { person.consumer_role }
  let!(:coverage_household) { family.households.first.coverage_households.first }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.households.first, coverage_household_id: coverage_household.id) }
  let!(:hbx_enrollment_member) {  FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.primary_applicant.id, eligibility_date: TimeKeeper.date_of_record) }

  context "family_members" do
    it "should return blank array" do
      allow(coverage_household).to receive(:family).and_return(nil)
      expect(coverage_household.family_members).to eq []
    end

    it "should return active_family_members" do
      expect(coverage_household.family_members).to eq [family.primary_applicant]
    end
  end

  describe CoverageHousehold, "when informed that eligiblity has changed for an individual" do

    before :each do
      coverage_household.update_attributes!(aasm_state: "unverified")
    end

    it "should locate and notify each coverage household containing that individual" do
      expect(coverage_household.aasm_state).to eq "unverified"
      CoverageHousehold.update_individual_eligibilities_for(consumer_role)
      coverage_household.reload
      expect(coverage_household.aasm_state).to eq "enrolled"
    end

    describe "and that individual exists on individual market policies" do

      describe "with a ruleset recommending contingent status" do
        it "should update it's state to match the state provided by the ruleset" do
          consumer_role.update_attributes!(aasm_state: "verification_outstanding")
          CoverageHousehold.update_individual_eligibilities_for(consumer_role)
          coverage_household.reload
          expect(coverage_household.aasm_state).to eq "enrolled_contingent"
        end
      end

      describe "with a ruleset recommending pending status" do
        it "should update it's state to match the state provided by the ruleset" do
          consumer_role.update_attributes!(aasm_state: "dhs_pending")
          CoverageHousehold.update_individual_eligibilities_for(consumer_role)
          expect(coverage_household.aasm_state).to eq "unverified"
        end
      end
    end
  end
end
