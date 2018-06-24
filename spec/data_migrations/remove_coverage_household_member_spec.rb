require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_coverage_household_member")

describe RemoveCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { "remove_coverage_household_member" }
  subject { RemoveCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "remove family member from coverage household", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:family_member){ FactoryGirl.create(:family_member,family: family, is_active: true)}

    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_id').and_return family_member.id
      allow(ENV).to receive(:[]).with('action').and_return('remove_fm_from_ch')
      chms = family.households.first.coverage_households.first.coverage_household_members << CoverageHouseholdMember.new(family_member_id: family_member.id, is_subscriber: false)
      chm = chms.where(family_member_id: family_member.id).first
      allow(ENV).to receive(:[]).with('coverage_household_member_id').and_return chm.id
      family.save
    end

    it "should remove a family member to household" do
      coverage_household_member = family.households.first.coverage_households.first.coverage_household_members
      expect(coverage_household_member.where(family_member_id: family_member.id).first).not_to eq nil
      subject.migrate
      family.reload
      expect(family.households.first.coverage_households.first.coverage_household_members.size).to eq 1
    end
  end

  describe "remove coverage household member", dbclean: :after_each do

    let(:person) {FactoryGirl.create(:person)}
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:family_member) {FactoryGirl.create(:family_member, family: family, is_active: true)}

    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_id').and_return family_member.id
      family.households.first.coverage_households.first.coverage_household_members << CoverageHouseholdMember.new(family_member_id: family_member.id, is_subscriber: false)
      chms = family.households.first.coverage_households.first.coverage_household_members << CoverageHouseholdMember.new(family_member_id: family_member.id, is_subscriber: false)
      chm = chms.where(family_member_id: family_member.id)[1]
      allow(ENV).to receive(:[]).with('coverage_household_member_id').and_return chm.id
      allow(ENV).to receive(:[]).with('action').and_return('remove_duplicate_chm')
    end

    it "coverage household member is greater than one" do
      coverage_household_member = family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: family_member.id)
      expect(coverage_household_member.count).to be > 1
      subject.migrate
      family.reload
      coverage_household_member = family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: family_member.id)
      expect(coverage_household_member.count).to eq 1
    end
  end

  describe "remove invalid family member from coverage household", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:family_member){ FactoryGirl.create(:family_member,family: family, is_active: true)}
    let(:action){ "remove_invalid_fm"}

    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_id').and_return family_member.id
      allow(ENV).to receive(:[]).with('action').and_return('remove_invalid_fm')
      chms = family.households.first.coverage_households.first.coverage_household_members << CoverageHouseholdMember.new(family_member_id: family_member.id, is_subscriber: false)
      chm = chms.where(family_member_id: family_member.id).first
      allow(ENV).to receive(:[]).with('coverage_household_member_id').and_return chm.id
      family.save
    end

    it "should remove a family member to household" do
      coverage_household_member = family.households.first.coverage_households.first.coverage_household_members
      expect(coverage_household_member.where(family_member_id: family_member.id).first).not_to eq nil
      subject.migrate
      family.reload
      expect(family.households.first.coverage_households.first.coverage_household_members.size).to eq 1
    end
  end
end
