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

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
    end

    it "should add a family member to household" do
      family.active_household.immediate_family_coverage_household.coverage_household_members.each do |chm|
        chm.delete
        expect(family.active_household.immediate_family_coverage_household.coverage_household_members.size).to eq 0
        subject.migrate
        family.active_household.reload
        expect(family.active_household.immediate_family_coverage_household.coverage_household_members.size).to eq 1
      end
    end

  end
end
