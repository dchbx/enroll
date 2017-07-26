require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_and_remove_enrollment_member")

describe AddAndRemoveEnrollmentMember, dbclean: :after_each do

  let(:given_task_name) { "add_and_remove_enrollment_member" }
  subject { AddAndRemoveEnrollmentMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member_and_dependent)}
    let(:primary) { family.primary_family_member }
    let(:dependents) { family.dependents }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:date) { DateTime.now - 10.days }
    let(:subscriber) { FactoryGirl.create(:hbx_enrollment_member, :hbx_enrollment => hbx_enrollment, eligibility_date: date, coverage_start_on: date, applicant_id: primary.id) }
    let(:hbx_en_member1) { FactoryGirl.create(:hbx_enrollment_member,
                                              :id => "111",
                                              :hbx_enrollment => hbx_enrollment,
                                              eligibility_date: date,
                                              coverage_start_on: date,
                                              applicant_id: dependents.first.id) }

    let(:new_member) { HbxEnrollmentMember.new({ :id => "222",
                                                 :applicant_id => dependents.last.id,
                                                 :eligibility_date => date,
                                                 :coverage_start_on => date}) }

    shared_examples_for "update members for hbx_enrollment" do |remove_id, add_id, result_count, has_member, no_member|
      before :each do
        hbx_enrollment.hbx_enrollment_members = [subscriber, hbx_en_member1]
        hbx_enrollment.save!
        allow(subject).to receive(:get_enrollment_input).and_return(hbx_enrollment.hbx_id)
        allow(subject).to receive(:get_person_to_remove_input).and_return(hbx_enrollment.hbx_enrollment_members.where(id: remove_id).first)
        allow(subject).to receive(:get_person_to_add_input).and_return(hbx_enrollment.hbx_enrollment_members.where(id: add_id).first)
        allow(subject).to receive(:get_enrollment_family).and_return(family)
        allow(subject).to receive(:delete_enrollment_member).and_return(hbx_enrollment.hbx_enrollment_members.where(id: remove_id).first.try(:delete)) unless (remove_id == 'skip' || remove_id == nil)
        allow(subject).to receive(:add_enrollment_member).and_return(hbx_enrollment.hbx_enrollment_members.push(new_member)) unless (add_id == 'skip' || add_id == nil)
        subject.migrate
      end

      it "hbx_enrollment has #{result_count} members" do
        expect(hbx_enrollment.hbx_enrollment_members.count).to eq result_count.to_i
      end
      it "enrollment has member #{has_member}" do
        expect(hbx_enrollment.hbx_enrollment_members).to include eval(has_member)
      end
      it "enrollment doesn't have a member #{no_member}" do
        expect(hbx_enrollment.hbx_enrollment_members).to_not include eval(no_member)
      end
    end

    it_behaves_like "update members for hbx_enrollment", 'skip', 'skip', '2', "subscriber", "new_member"
    it_behaves_like "update members for hbx_enrollment", '111', 'skip', '1', "subscriber", "hbx_en_member1"
    it_behaves_like "update members for hbx_enrollment", '111', 'new_member', '2', "new_member", "hbx_en_member1"
  end
end

