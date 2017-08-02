require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_family_members_to_immediate_coverage_household_members")

describe AddFamilyMembersToImmediateCoverageHouseholdMembers, dbclean: :after_each do

  let(:given_task_name) { "add_coverage_household_members" }
  subject { AddFamilyMembersToImmediateCoverageHouseholdMembers.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "adding family members to coverage household members", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:household) { FactoryGirl.create(:household, family: family)}
    let(:coverage_household) {CoverageHousehold.new}
    let(:spouse) { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 50.years) }
    let(:child)  { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 12.years) }
    let(:family_members){[spouse, child]}

    before do
      allow(coverage_household).to receive(:household).and_return(household)
      allow(family).to receive(:family_members).and_return(family_members)
      allow(person.primary_family).to receive(:family_members).and_return(family_members)
      allow(family.active_household.immediate_family_coverage_household.family).to receive(:family_members).and_return(family_members)
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
    end
    
    it "immediate coverage household should have one coverage household member" do
      expect(family.active_household.immediate_family_coverage_household.coverage_household_members.map(&:family_member).count).to eq 1
    end
    
    it "should add family members" do
      subject.migrate
    end
  end
end