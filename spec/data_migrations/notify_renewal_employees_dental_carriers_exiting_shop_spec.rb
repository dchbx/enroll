require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'notify_renewal_employees_dental_carriers_exiting_shop')

describe NotifyRenewalEmployeesDentalCarriersExitingShop, dbclean: :after_each do

  let(:given_task_name) { 'notify_renewal_employees_dental_carriers_exiting_shop' }
  subject { NotifyRenewalEmployeesDentalCarriersExitingShop.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe '#trigger notify_renewal_employees_dental_carriers_exiting_shop', type: :model, dbclean: :after_each do
    let!(:person) { FactoryBot.create(:person, hbx_id: '19877154') }
    let!(:employer_profile) { create(:employer_with_planyear)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family,
        household: family.active_household,
        coverage_kind: 'dental',
        kind: 'employer_sponsored',
        plan_id: plan.id,
        employee_role_id: employee_role.id
      )
    end
    let!(:organization) {FactoryBot.create(:organization, legal_name: 'Delta Dental')}
    let!(:carrier_profile) {FactoryBot.create(:carrier_profile, organization: organization)}
    let!(:plan) {FactoryBot.create(:plan, :with_dental_coverage, carrier_profile: carrier_profile)}
    let!(:employee_role) { FactoryBot.create(:employee_role, employer_profile: employer_profile, person: person, census_employee_id: census_employee.id) }
    let!(:census_employee) { FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile) }

    before(:each) do
      census_employee.update_attributes(employee_role_id: employee_role.id)
    end

    it 'should trigger notify_renewal_employees_dental_carriers_exiting_shop job in queue' do
      ClimateControl.modify hbx_id: person.hbx_id do
        ActiveJob::Base.queue_adapter = :test
        ActiveJob::Base.queue_adapter.enqueued_jobs = []
        subject.migrate

        queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
          job_info[:job] == ShopNoticesNotifierJob
        end

        expect(queued_job[:args]).not_to be_empty
        expect(queued_job[:args].include?('notify_renewal_employees_dental_carriers_exiting_shop')).to be_truthy
        expect(queued_job[:args].include?("#{hbx_enrollment.census_employee.id.to_s}")).to be_truthy
        expect(queued_job[:args].third['hbx_enrollment']).to eq hbx_enrollment.hbx_id.to_s
      end
    end
  end
end
