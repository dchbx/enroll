require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_family_member_to_coverage_household")

describe AddFamilyMemberToCoverageHousehold, dbclean: :after_each do

  let(:given_task_name) { "add_family_member_to_coverage_household" }
  subject { AddFamilyMemberToCoverageHousehold.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add family member to coverage household", dbclean: :after_each do

    let!(:person) { FactoryGirl.create(:person, :with_family) }
    let!(:dependent) { FactoryGirl.create(:person) }
    let!(:family_member) { FactoryGirl.create(:family_member, family: person.primary_family ,person: dependent)}
    let!(:coverage_household_member) { coverage_household.coverage_household_members.new(:family_member_id => family_member.id) }
    let(:primary_family){person.primary_family}
    let(:coverage_household){person.primary_family.active_household.immediate_family_coverage_household}

    before do
      allow(ENV).to receive(:[]).with('primary_hbx_id').and_return person.hbx_id
    end

    it "should add a family member to immediate family coverage household" do
      allow(ENV).to receive(:[]).with('dependent_hbx_id').and_return dependent.hbx_id
      expect(coverage_household.coverage_household_members.size).to eq 2
      chm = coverage_household.coverage_household_members[1]
      chm.destroy!
      expect(coverage_household.coverage_household_members.size).to eq 1
      subject.migrate
      primary_family.active_household.reload
      expect(coverage_household.coverage_household_members.size).to eq 1
    end

    it "should add a primary applicant to immediate family coverage household" do
      allow(ENV).to receive(:[]).with('dependent_hbx_id').and_return person.hbx_id
      expect(coverage_household.coverage_household_members.size).to eq 2
      chm = coverage_household.coverage_household_members[0]
      chm.destroy!
      expect(coverage_household.coverage_household_members.size).to eq 1
      subject.migrate
      primary_family.active_household.reload
      expect(coverage_household.coverage_household_members.size).to eq 1
    end
  end
end
