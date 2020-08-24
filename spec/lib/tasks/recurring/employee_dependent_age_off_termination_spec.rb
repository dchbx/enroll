require 'rails_helper'
require 'rake'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

describe 'recurring:employee_dependent_age_off_termination', :dbclean => :around_each do
  before :each do
    TimeKeeper.set_date_of_record_unprotected!(Date.current)
  end

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let!(:person) { FactoryBot.create(:person) }
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, active_benefit_group_assignment: current_benefit_package.id) }
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id)}

  let!(:benefit_group_assignment)  { census_employee.active_benefit_group_assignment }
  let!(:person2) { FactoryBot.create(:person, dob: TimeKeeper.date_of_record - 30.years) }
  let!(:person3) { FactoryBot.create(:person, dob: TimeKeeper.date_of_record - 30.years) }
  let!(:family) do
    family = FactoryBot.build(:family, :with_primary_family_member, person: person)
    family.relate_new_member(person2, 'child')
    family.relate_new_member(person3, 'child')
    family.save
    person.save
    family
  end

  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, household: family.households.first, kind: "employer_sponsored", family: family, aasm_state: "coverage_selected", benefit_group_assignment_id: benefit_group_assignment.id) }
  let!(:hbx_enrollment_member1){ FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[0].id, eligibility_date: TimeKeeper.date_of_record.prev_month) }
  let!(:hbx_enrollment_member2){ FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[1].id, eligibility_date: TimeKeeper.date_of_record.prev_month, is_subscriber: false) }
  let!(:hbx_enrollment_member3){ FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[2].id, eligibility_date: TimeKeeper.date_of_record.prev_month, is_subscriber: false) }

  before do
    load File.expand_path("#{Rails.root}/lib/tasks/recurring/employee_dependent_age_off_termination.rake", __FILE__)
    Rake::Task.define_task(:environment)
  end

  pending "should trigger employee_dependent_age_off_termination notice"
  # it "should trigger employee_dependent_age_off_termination notice" do
  #   expect_any_instance_of(BenefitSponsors::Observers::NoticeObserver).to receive(:deliver)
  #   person.employee_roles.first.update_attributes(census_employee_id: census_employee.id)
  #   allow(TimeKeeper).to receive(:date_of_record).and_return TimeKeeper.date_of_record.beginning_of_month
  #   Rake::Task["recurring:employee_dependent_age_off_termination"].invoke
  # end

  context 'recurring:dependent_age_off_termination_notification_manual' do
    pending "should trigger dependent age off notice"
    # it "should trigger dependent age off notice" do
    #   expect_any_instance_of(BenefitSponsors::Observers::NoticeObserver).to receive(:deliver)
    #   person.employee_roles.first.update_attributes(census_employee_id: census_employee.id)
    #   Rake::Task["recurring:dependent_age_off_termination_notification_manual"].invoke(person.hbx_id)
    # end
  end

  context 'recurring:dependent_age_off_termination_notification_manual' do
    it "should trigger dependent age off notice for next month" do
      person2.update_attributes(dob: TimeKeeper.date_of_record.next_month - 26.years)
      person3.update_attributes(dob: TimeKeeper.date_of_record.next_month - 25.years)
      allow(TimeKeeper).to receive(:date_of_record).and_return TimeKeeper.date_of_record.next_month.beginning_of_month

      expect_any_instance_of(BenefitSponsors::Observers::NoticeObserver).to receive(:deliver)
      person.employee_roles.first.update_attributes(census_employee_id: census_employee.id)
      Rake::Task["recurring:dependent_age_off_termination_notification_manual"].reenable
      Rake::Task["recurring:dependent_age_off_termination_notification_manual"].invoke(person.hbx_id)
    end
  end
end
