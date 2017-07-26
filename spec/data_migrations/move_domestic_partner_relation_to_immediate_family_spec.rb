require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_domestic_partner_relation_to_immediate_family")
describe MoveDomesticPartnerRelationToImmediateFamily, dbclean: :after_each do
  let(:given_task_name) { "move_domestic_partner_relation_to_immediate_family" }
  subject { MoveDomesticPartnerRelationToImmediateFamily.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "move domestic partner relation to immediate family", dbclean: :after_each do
    let(:family) {
      family = FactoryGirl.build(:family, :with_primary_family_member_and_dependent)
      primary_person = family.family_members.where(is_primary_applicant: true).first.person
      other_person = family.family_members.where(is_primary_applicant: false).first.person
      other_child_person = family.family_members.where(is_primary_applicant: false).last.person
      primary_person.person_relationships << PersonRelationship.new(relative_id: other_person.id, kind: "domestic_partner")
      primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person.id, kind: "child")
      primary_person.save
      other_person.save
      family.save
      family
    }

    let(:immediate_ch) { CoverageHousehold.new(is_immediate_family: true)}
    let(:non_immediate_ch) { CoverageHousehold.new(is_immediate_family: false)}
    before(:each) do
      immediate_ch.add_coverage_household_member(family.family_members.where(is_primary_applicant: true).first)
      family.active_household.coverage_households << immediate_ch
      non_immediate_ch.add_coverage_household_member(family.family_members.where(is_primary_applicant: false).first)
      family.active_household.coverage_households << non_immediate_ch
      family.active_household.save!
    end

    it "should not have the domestic_partner member under non-immediate coverage household" do
      size = family.active_household.coverage_households.where(is_immediate_family: false).first.coverage_household_members.size
      subject.migrate
      family.active_household.reload
      expect(family.active_household.coverage_households.where(is_immediate_family: false).first.coverage_household_members.size).to eq size-1
    end

    it "should have the domestic_partner member under immediate coverage household" do
      size = family.active_household.coverage_households.where(is_immediate_family: true).first.coverage_household_members.size
      subject.migrate
      family.active_household.reload
      expect(family.active_household.coverage_households.where(is_immediate_family: true).first.coverage_household_members.size).to eq size+1
      expect(family.active_household.coverage_households.where(is_immediate_family: true).first.coverage_household_members.flat_map(&:family_member).map(&:relationship)).to eq ["self", "domestic_partner"]
    end
  end
end
