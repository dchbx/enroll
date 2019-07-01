require 'rails_helper'
require 'rake'

describe 'Cancel employer plan year & enrollments', :dbclean => :around_each do

  let(:benefit_group) { FactoryBot.create(:benefit_group)}
  let(:benefit_group1) { FactoryBot.create(:benefit_group)}
  let(:active_plan_year)  { FactoryBot.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.end_of_month, aasm_state: 'active',benefit_groups:[benefit_group]) }
  let(:renewal_plan_year)  { FactoryBot.build(:plan_year,start_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.months, end_on: (TimeKeeper.date_of_record.next_month+1.year).end_of_month, aasm_state:'renewing_enrolling',benefit_groups:[benefit_group1]) }
  let(:employer_profile)     { FactoryBot.build(:employer_profile, plan_years: [active_plan_year,renewal_plan_year]) }
  let(:organization) { FactoryBot.create(:organization, employer_profile:employer_profile)}
  let(:family) { FactoryBot.build(:family, :with_primary_family_member)}
  let(:census_employee)   { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
  let(:employee_role)   { FactoryBot.build(:employee_role, employer_profile: employer_profile )}
  let(:enrollment) { FactoryBot.build(:hbx_enrollment, family: family, household: family.active_household, employee_role: census_employee.employee_role)}
  let(:enrollment2) { FactoryBot.build(:hbx_enrollment,family: family, household: family.active_household, employee_role: census_employee.employee_role,aasm_state:'auto_renewing')}
  let(:active_benefit_group_assignment) {census_employee.benefit_group_assignments.where(:benefit_group_id.in =>[benefit_group.id]).first}
  let(:renewal_benefit_group_assignment) {census_employee.benefit_group_assignments.where(:benefit_group_id.in =>[benefit_group1.id]).first}

  describe 'migrations:cancel_employer_incorrect_renewal' do

    before do
      enrollment.update_attributes(benefit_group_id: benefit_group.id, aasm_state:'coverage_selected')
      active_benefit_group_assignment.update_attributes(hbx_enrollment_id:enrollment.id,aasm_state:'coverage_selected')
      load File.expand_path("#{Rails.root}/lib/tasks/migrations/cancel_employer_renewal.rake", __FILE__)
      Rake::Task.define_task(:environment)
      Rake::Task["migrations:cancel_employer_incorrect_renewal"].reenable
      fein = organization.fein
      Rake::Task["migrations:cancel_employer_incorrect_renewal"].invoke(fein)
    end

    it 'should cancel plan year and enrollments' do
      active_plan_year.reload
      enrollment.reload
      active_benefit_group_assignment.reload
      expect(active_plan_year.aasm_state).to eq "canceled"
      expect(enrollment.aasm_state).to eq "coverage_canceled"
      expect(active_benefit_group_assignment.aasm_state).to eq "initialized"
      expect(active_benefit_group_assignment.is_active).to eq false
    end

    it 'should not cancel incorrect plan year and enrollments' do
      active_plan_year.update_attribute(:aasm_state,'published')
      active_plan_year.reload
      expect(active_plan_year.aasm_state).to eq "published"
      expect(enrollment.aasm_state).to eq "coverage_selected"
      expect(active_benefit_group_assignment.aasm_state).to eq "coverage_selected"
      expect(active_benefit_group_assignment.is_active).to eq true
    end
  end

  describe 'migrations:cancel_employer_renewal' do

    before do
      enrollment2.update_attributes!(benefit_group_id: benefit_group1.id, aasm_state:'auto_renewing')
      renewal_benefit_group_assignment.update_attributes(hbx_enrollment_id:enrollment2.id, is_active:true, aasm_state:'coverage_renewing')
      load File.expand_path("#{Rails.root}/lib/tasks/migrations/cancel_employer_renewal.rake", __FILE__)
      Rake::Task.define_task(:environment)
      fein = organization.fein
      Rake::Task["migrations:cancel_employer_renewal"].invoke(fein)
    end

    it 'should cancel renewing plan year and enrollments' do
      renewal_plan_year.reload
      enrollment2.reload
      renewal_benefit_group_assignment.reload
      expect(renewal_plan_year.aasm_state).to eq "renewing_canceled"
      expect(enrollment2.aasm_state).to eq "coverage_canceled"
      expect(renewal_benefit_group_assignment.aasm_state).to eq "initialized"
      expect(renewal_benefit_group_assignment.is_active).to eq false
    end

    it 'should not cancel plan year and enrollments' do
      renewal_plan_year.update_attribute(:aasm_state,'published')
      renewal_plan_year.reload
      expect(renewal_plan_year.aasm_state).to eq "published"
      expect(enrollment2.aasm_state).to eq "auto_renewing"
      expect(renewal_benefit_group_assignment.aasm_state).to eq "coverage_renewing"
      expect(renewal_benefit_group_assignment.is_active).to eq true
    end
  end

end
