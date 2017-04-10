require 'rails_helper'
require 'pry'

require File.join(Rails.root, "app", "data_migrations", "fix_is_subscriber_for_responsible_party_enrollments")

describe FixIsSubscriberForResponsiblePartyEnrollments do
  let(:given_task_name) { "fix_is_subscriber_for_responsible_party_enrollments" }
  subject { FixIsSubscriberForResponsiblePartyEnrollments.new(given_task_name, double(current_scope: nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "given an responsible party enrollment with no active subscribers" do
    let(:dependent_1) { FactoryGirl.create(:person, hbx_id: 1, dob: TimeKeeper.date_of_record - 1.week, ssn: '555555551') }
    let(:dependent_2) { FactoryGirl.create(:person, hbx_id: 2, dob: TimeKeeper.date_of_record - 1.year, ssn: '555555552') }
    let(:family_relationships) { [
      PersonRelationship.new(relative: dependent_1, kind: "child"),
      PersonRelationship.new(relative: dependent_2, kind: "child")]
    }
    let(:subscriber) { FactoryGirl.create(
      :person,
      person_relationships: family_relationships,
      dob: TimeKeeper.date_of_record - 30.years,
      ssn: '555555550')
    }
    let(:family_members) { [subscriber, dependent_1, dependent_2] }
    let(:family) { FactoryGirl.create(:family, :with_family_members, person: subscriber, people: family_members) }
    let(:family_member_1) { family.family_members.where(person_id: dependent_1).first }
    let(:family_member_2) { family.family_members.where(person_id: dependent_2).first }
    let(:hbx_enrollment_member_1) {
      FactoryGirl.create(:hbx_enrollment_member,
        is_subscriber: false,
        applicant_id: family_member_1.id,
        hbx_enrollment: hbx_enrollment,
        eligibility_date: TimeKeeper.date_of_record.beginning_of_month,
        coverage_start_on: TimeKeeper.date_of_record.beginning_of_month)
    }
    let(:oldest_hbx_enrollment_member) {
      FactoryGirl.create(:hbx_enrollment_member,
        is_subscriber: false,
        applicant_id: family_member_2.id,
        hbx_enrollment: hbx_enrollment,
        eligibility_date: TimeKeeper.date_of_record.beginning_of_month,
        coverage_start_on: TimeKeeper.date_of_record.beginning_of_month)
    }
    let(:hbx_enrollment) {
      FactoryGirl.create(:hbx_enrollment,
        :individual_unassisted,
        household: family.active_household)
    }

    before :each do
      allow(hbx_enrollment_member_1).to receive(:family_member).and_return(family_member_1)
      allow(oldest_hbx_enrollment_member).to receive(:family_member).and_return(family_member_2)
      allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hbx_enrollment_member_1, oldest_hbx_enrollment_member])
    end

    it "should set is_subscriber to true for the oldest applicant" do
      hbx_enrollment.hbx_enrollment_members.each do |member|
        expect(member.is_subscriber).to be(false)
      end

      subject.migrate
      oldest_hbx_enrollment_member.reload
      hbx_enrollment_member_1.reload
      expect(oldest_hbx_enrollment_member.is_subscriber).to be(true)
      expect(hbx_enrollment_member_1.is_subscriber).to be(false)
    end
  end
end
