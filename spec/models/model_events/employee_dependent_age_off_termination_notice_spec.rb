require 'rails_helper'

describe 'ModelEvents::EmployeeDependentAgeOffTerminationNotice', :dbclean => :after_each do
let(:start_on) { TimeKeeper.date_of_record.beginning_of_month.next_month.prev_year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:primary_person){ FactoryGirl.create(:person)}
  let!(:person2){ FactoryGirl.create(:person)}
  let!(:person3){ FactoryGirl.create(:person)}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'application_ineligible' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: primary_person, employer_profile: employer_profile, benefit_group_id: active_benefit_group.id )}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee, start_on: start_on) }
  let(:date) {TimeKeeper.date_of_record}
  let!(:family) {
      family = FactoryGirl.build(:family, :with_primary_family_member, person: primary_person)
      family_member2 = FactoryGirl.create(:family_member, family: family, person: person2)
      family_member3 = FactoryGirl.create(:family_member, family: family, person: person3)
      primary_person.person_relationships << PersonRelationship.new(relative_id: person2.id, kind: "child")
      primary_person.person_relationships << PersonRelationship.new(relative_id: person3.id, kind: "child")
      primary_person.save!
      person2.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 25.years
      person3.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 25.years
      family.save!
      family
    }

  let(:enrollment) do
    hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "individual")
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).first.id, is_subscriber: false)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).last.id, is_subscriber: false)
    hbx.save
    hbx
  end

  let(:dep_hbx_ids) { [person2.hbx_id, person3.hbx_id] }

  before do
    allow(employee_role).to receive(:census_employee).and_return(census_employee)
    allow(TimeKeeper).to receive(:date_of_record).and_return TimeKeeper.date_of_record.beginning_of_month
  end

  describe "NoticeTrigger" do
    context "First of the month when dependebt child turns 26" do
      subject { Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_notice_dependent_age_off_termination_non_congressional"
          expect(payload[:event_object_kind]).to eq 'CensusEmployee'
          expect(payload[:event_object_id]).to eq census_employee.id.to_s
        end
        subject.deliver(recipient: employee_role, event_object: census_employee, notice_event: "employee_notice_dependent_age_off_termination_non_congressional")
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.dependents_name",
        "employee_profile.dependent_termination_date",
        "employee_profile.broker.organization"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "CensusEmployee",
        "event_object_id" => census_employee.id,
        "notice_params" => {"dep_hbx_ids" => dep_hbx_ids}
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)

    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return employee first name" do
      expect(merge_model.first_name).to eq primary_person.first_name
    end

    it "should return employee last name" do
      expect(merge_model.last_name).to eq primary_person.last_name
    end

    it "should return dependents name" do
      expect(merge_model.dependents_name).to eq [person2.full_name, person3.full_name].join(", ")
    end

    it "should return dependent termination date" do
      expect(merge_model.dependent_termination_date).to eq date.end_of_month.strftime('%m/%d/%Y')
    end
  end
end
