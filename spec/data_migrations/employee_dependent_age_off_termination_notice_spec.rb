require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "employee_dependent_age_off_termination_notice")

describe EmployeeDependentAgeOffTerminationNotice, dbclean: :after_each do

  let(:given_task_name) { "employee_dependent_age_off_termination_notice" }

  subject { EmployeeDependentAgeOffTerminationNotice.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "dependent age off termination notice" do
    let!(:person) { FactoryGirl.create(:person, hbx_id: '238474') }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile, benefit_group_id: active_benefit_group.id)}
    let!(:census_employee) { FactoryGirl.create(:census_employee, aasm_state: "eligible", employee_role_id: employee_role.id,) }
    let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, :aasm_state => 'active')}
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
    let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
    let!(:person2) { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 30.years) }
    let!(:person3) { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 30.years) }
    let!(:family) {
                  family = FactoryGirl.build(:family, :with_primary_family_member, person: person)
                  FactoryGirl.create(:family_member, family: family, person: person2)
                  FactoryGirl.create(:family_member, family: family, person: person3)
                  person.person_relationships.create(predecessor_id: person.id, successor_id: person2.id, family_id: family.id, relative_id: person2.id, kind: "child")
                  person.person_relationships.create(predecessor_id: person.id, successor_id: person3.id, family_id: family.id, relative_id: person3.id, kind: "child")
                  person.save!
                  family.save!
                  family
                }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "employer_sponsored", aasm_state: "coverage_selected", benefit_group_assignment_id: benefit_group_assignment.id) }
    let!(:hbx_enrollment_member1){ FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[0].id, eligibility_date: TimeKeeper.date_of_record - 1.month) }
    let!(:hbx_enrollment_member2){ FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[1].id, eligibility_date: TimeKeeper.date_of_record - 1.month, is_subscriber: false) }
    let!(:hbx_enrollment_member3){ FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[2].id, eligibility_date: TimeKeeper.date_of_record - 1.month, is_subscriber: false) }

    let!(:observer) { Observers::NoticeObserver.new }

    before do
      allow(ENV).to receive(:[]).with("hbx_ids").and_return(person.hbx_id)
      allow(TimeKeeper).to receive(:date_of_record).and_return TimeKeeper.date_of_record.beginning_of_month
    end

    it "should trigger non congressional notice" do
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: census_employee, notice_event: 'employee_notice_dependent_age_off_termination_non_congressional',  notice_params: {dep_hbx_ids: [hbx_enrollment_member2.person.hbx_id, hbx_enrollment_member3.person.hbx_id]})
      person.employee_roles.first.update_attributes(census_employee_id: census_employee.id)
      subject.migrate
    end

    it "should trigger congressional notice" do
      active_benefit_group.update_attributes(is_congress: true)
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: census_employee, notice_event: 'employee_notice_dependent_age_off_termination_congressional',  notice_params: {dep_hbx_ids: [hbx_enrollment_member2.person.hbx_id, hbx_enrollment_member3.person.hbx_id]})
      person.employee_roles.first.update_attributes(census_employee_id: census_employee.id)
      subject.migrate
    end
  end
end