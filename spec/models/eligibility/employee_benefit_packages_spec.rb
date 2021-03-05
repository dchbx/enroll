# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Eligibility::EmployeeBenefitPackages, type: :model, dbclean: :around_each do

  describe 'create_benefit_group_assignment' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:benefit_package)      { initial_application.benefit_packages.first }
    let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }

    context 'census employee has no benefit group assignments' do
      it 'should create new benefit group assignment' do
        expect(census_employee.benefit_group_assignments.count).to eq 0
        census_employee.create_benefit_group_assignment(initial_application.benefit_packages, off_cycle: false, reinstated: false)
        census_employee.reload
        expect(census_employee.benefit_group_assignments.count).to eq 1
      end
    end

    context 'if census employee has already a benefit group assignment which starts in future' do
      let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
      let!(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

      it 'should create new benefit group assignment and end date the old one with start on date' do
        expect(census_employee.benefit_group_assignments.count).to eq 1
        census_employee.create_benefit_group_assignment(initial_application.benefit_packages, off_cycle: false, reinstated: false)
        census_employee.reload
        expect(census_employee.benefit_group_assignments.count).to eq 2
      end

      it 'should end date the old bga with the benefit package start on' do
        period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
        initial_application.update_attributes!(effective_period: period)
        benefit_group_assignment.update_attributes(start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.create_benefit_group_assignment(initial_application.benefit_packages, off_cycle: false, reinstated: false)
        census_employee.reload
        benefit_group_assignment.reload
        expect(benefit_group_assignment.end_on).to eq benefit_package.start_on
      end
    end

    context 'if census employee has already a future reinstated benefit group assignment which starts in future' do
      let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
      let!(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

      before do
        period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
        initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
        benefit_group_assignment.update_attributes(start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
        census_employee.save
      end

      it 'should end date the old bga with the benefit package start on' do
        census_employee.create_benefit_group_assignment(initial_application.benefit_packages, off_cycle: false, reinstated: true)
        census_employee.reload
        benefit_group_assignment.reload
        expect(census_employee.benefit_group_assignments.count).to eq 2
        expect(benefit_group_assignment.end_on).to eq benefit_package.start_on
      end
    end
  end

  describe 'reinstated_benefit_group_with_future_date' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:benefit_package)      { initial_application.benefit_packages.first }

    before do
      period = initial_application.effective_period.min + 1.year..(initial_application.effective_period.max + 1.year)
      initial_application.update_attributes!(reinstated_id: BSON::ObjectId.new, aasm_state: :active, effective_period: period)
      benefit_group_assignment.update_attributes(start_on: initial_application.start_on, end_on: initial_application.end_on)
      census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
      census_employee.save
    end

    context 'return benefit group assignment if present' do
      let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
      let!(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package, census_employee: census_employee)}

      it 'should return object' do
        expect(census_employee.reinstated_benefit_group_with_future_date).to eq benefit_group_assignment.benefit_package
      end

      it 'should return nil if no reinstated PY present' do
        initial_application.update_attributes!(aasm_state: :enrollment_open, reinstated_id: nil)
        benefit_group_assignment.update_attributes(start_on: initial_application.start_on, end_on: initial_application.end_on)
        census_employee.benefit_sponsorship = abc_profile.benefit_sponsorships.first
        expect(census_employee.reinstated_benefit_group_with_future_date).to eq nil
      end
    end
  end
end
