# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_coverage_household_member")

describe UpdateCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { "update_coverage_household_member" }
  subject { UpdateCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating coverage household member", dbclean: :after_each do

    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:imm_fam_coverage_hh) { family.active_household.immediate_family_coverage_household }
    let(:other_fam_coverage_hh) { family.active_household.coverage_households.where(:id.ne => imm_fam_coverage_hh.id).first }

    before :each do
      imm_fam_coverage_hh.coverage_household_members.destroy_all
      chhm = other_fam_coverage_hh.coverage_household_members.build(family_member_id: family.family_members[0].id, is_subscriber: true)
      chhm.save
    end

    around do |example|
      ClimateControl.modify hbx_id: person.hbx_id do
        example.run
      end
    end

    it "should update coverage household" do
      expect(imm_fam_coverage_hh.coverage_household_members.present?).to be_falsey
      expect(other_fam_coverage_hh.coverage_household_members.present?).to be_truthy
      subject.migrate
      expect(imm_fam_coverage_hh.reload.coverage_household_members.present?).to be_truthy
      expect(other_fam_coverage_hh.reload.coverage_household_members.present?).to be_falsey
    end
  end
end
