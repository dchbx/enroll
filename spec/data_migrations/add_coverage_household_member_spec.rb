require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_coverage_household_member")

describe AddCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { "add_coverage_household_member" }
  subject { AddCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "adding coverage household member", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_id').and_return family.family_members.first.id
    end

    it "should add a household" do
      family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.each do |chm|
        chm.delete
        subject.migrate
        family.households.first.reload
        expect(family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members).not_to eq []
      end
    end


    it "should not add a household if already exists" do
      size = family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.size
      subject.migrate
      family.households.first.reload
      expect(family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.size).to eq size
    end
  end
end
