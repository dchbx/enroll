# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_all_duplicate_family_members")

describe RemoveAllDuplicateFamilyMembers, dbclean: :after_each do
  let!(:most_recent_active_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      household: family.active_household,
      family: family,
      aasm_state: "coverage_selected"
    )
  end
  let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household) }
  let(:given_task_name) { "remove_all_duplicate_dependents" }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
  let(:dependent) { family.family_members.where(is_primary_applicant: false).first }
  subject { RemoveAllDuplicateFamilyMembers.new(given_task_name, double(:current_scope => nil)) }

  around do |example|
    ClimateControl.modify most_recent_active_enrollment_hbx_id: most_recent_active_enrollment.hbx_id.to_s do
      example.run
    end
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Should remove duplicate family members", dbclean: :after_each do
    before :each do
      # Create HBX enrollment members
      family.family_members.each do |family_member|
        most_recent_active_enrollment.hbx_enrollment_members.create!(
          applicant_id: family_member.id,
          is_subscriber: true,
          coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
          eligibility_date: TimeKeeper.date_of_record - 2.months
        )
      end
      expect(family.family_members.count).to eq(3)
      # Create family member with the same info
      family.family_members << FamilyMember.new(person_id: dependent.person.id)
      dup_fm = family.family_members.last
      dup_fm.save(validate: false)
      family.active_household.add_household_coverage_member(dup_fm)
      dup_fm
      expect(family.family_members.count).to eq(4)
      subject.migrate
      family.reload
    end

    it "should remove duplicate family member" do
      expect(family.family_members.count).to eq(3)
    end

    it "should return # of coverage household members equal to enrollment hbx enrollment member count" do
      expect(family.active_household.coverage_households.first.coverage_household_members.count).to eq(3)
    end

    it "should return # of tax household members equal to enrollment hbx enrollment member count" do
      expect(family.active_household.tax_households.first.tax_household_members.count).to eq(3)
    end
  end

  describe "Should not error out", dbclean: :after_each do
    context 'HbxEnrollment does not exist or blank string passed as arguement' do
      around do |example|
        ClimateControl.modify most_recent_active_enrollment_hbx_id: "" do
          example.run
        end
      end

      it 'should do nothing' do
        subject.migrate
      end
    end
  end
end
