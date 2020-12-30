# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_dependent")
require File.join(Rails.root, "lib", "remove_family_member")

describe RemoveDependent, dbclean: :after_each do

  let(:given_task_name) { "remove_dependent" }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
  let(:dependent) { family.family_members.where(is_primary_applicant: false).first }
  subject { RemoveDependent.new(given_task_name, double(:current_scope => nil)) }

  around do |example|
    ClimateControl.modify family_member_ids: dependent.id.to_s do
      example.run
    end
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Should remove duplicate dependents", dbclean: :after_each do

    it "should remove duplicate family member" do
      size = family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.size
      family.households.first.coverage_households.where(:is_immediate_family => false).first.coverage_household_members.each do |chm|
        chm.delete
        subject.migrate
        family.households.first.reload
        expect(family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.count).not_to eq(size)
      end
    end

    context 'should not have any dependecies to delete FM record' do
      let!(:duplicate_family_member) do
        family.family_members << FamilyMember.new(person_id: dependent.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        dup_fm
      end

      around do |example|
        ClimateControl.modify family_member_ids: duplicate_family_member.id.to_s do
          example.run
        end
      end

      it 'should delete FM record' do
        subject.migrate
        family.reload
        expect { family.family_members.find(duplicate_family_member.id.to_s) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context '2 family members exists with coverage_household_members for same person' do
      let!(:duplicate_family_member) do
        family.family_members << FamilyMember.new(person_id: dependent.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        family.active_household.add_household_coverage_member(dup_fm)
        dup_fm
      end

      around do |example|
        ClimateControl.modify family_member_ids: duplicate_family_member.id.to_s do
          example.run
        end
      end

      before :each do
        subject.migrate
        family.reload
      end

      it 'should delete FM record' do
        expect { family.family_members.find(duplicate_family_member.id.to_s) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it 'should delete CHM record' do
        chmms = family.active_household.coverage_households.flat_map(&:coverage_household_members)
        expect(family.family_members.count).to eq(chmms.count)
        expect(chmms.map(&:family_member_id).map(&:to_s)).not_to include(duplicate_family_member.id.to_s)
      end
    end
  end

  describe "Should not remove duplicate dependents", dbclean: :after_each do

    it "should not remove family member" do
      size = family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.size
      expect(size).to eq 3
      subject.migrate
      family.reload
      expect(family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.size).to eq(size)
    end

    context 'Family Member does not exist' do
      around do |example|
        ClimateControl.modify family_member_ids: family.id.to_s do
          example.run
        end
      end

      it 'should do nothing' do
        subject.migrate
      end
    end

    context 'duplicate FM record does not exist' do
      before do
        subject.migrate
      end

      it 'should not delete FM record' do
        expect(family.family_members.find(dependent.id.to_s)).to be_a FamilyMember
      end
    end

    context 'Mapping Coverage Household Member exist' do
      before do
        subject.migrate
      end

      it 'should not delete FM record' do
        expect(family.family_members.find(dependent.id.to_s)).to be_a FamilyMember
      end
    end

    context 'Mapping Tax Household Member exist' do
      let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household) }
      let!(:tax_household_member1) { FactoryBot.create(:tax_household_member, applicant_id: dependent.id.to_s, tax_household: tax_household) }

      before do
        subject.migrate
      end

      it 'should not delete FM record' do
        expect(family.family_members.find(dependent.id.to_s)).to be_a FamilyMember
      end
    end

    context 'Matching Hbx Enrollment Member exist with shopping state' do
      let!(:enrollment) do
        enr = FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: "shopping")
        enr.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: dependent.id.to_s, eligibility_date: Time.zone.today, coverage_start_on: Time.zone.today)
        enr.hbx_enrollment_members.first.save!
        enr.save!
        enr
      end

      let!(:matched_hbx_member) do
        enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: duplicate_family_member.id.to_s, eligibility_date: Time.zone.today, coverage_start_on: Time.zone.today)
        enrollment.hbx_enrollment_members.last.save!
        enrollment.save!
        enrollment.hbx_enrollment_members.last
      end

      let!(:duplicate_family_member) do
        family.family_members << FamilyMember.new(person_id: dependent.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        dup_fm
      end

      let!(:size) {enrollment.hbx_enrollment_members.count}

      around do |example|
        ClimateControl.modify family_member_ids: duplicate_family_member.id.to_s do
          example.run
        end
      end

      before do
        subject.migrate
      end

      it 'should delete FM record' do
        family.reload
        expect { family.family_members.find(duplicate_family_member.id.to_s) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it 'should delete shopping enrollment membre record linked with duplicate family member' do
        enrollment.reload
        expect(enrollment.hbx_enrollment_members.count).not_to eq(size)
      end
    end

    context 'Mapping Hbx Enrollment Member exist with not in shopping state' do
      let!(:enrollment) do
        enr = FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)
        enr.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: dependent.id.to_s, eligibility_date: Time.zone.today, coverage_start_on: Time.zone.today)
        enr.hbx_enrollment_members.first.save!
        enr.save!
        enr
      end

      before do
        subject.migrate
      end

      it 'should not delete FM record' do
        expect(family.family_members.find(dependent.id.to_s)).to be_a FamilyMember
      end
    end
  end
end
