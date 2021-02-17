# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::BenefitGroupAssignments::Reinstate, :type => :model, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:benefit_application)    { initial_application }
  let(:employer_profile)       {  abc_profile }
  let(:initial_benefit_package) { initial_application.benefit_packages.first }
  let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
  let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: initial_benefit_package, start_on: initial_benefit_package.start_on,  census_employee: census_employee)}

  context 'Failure' do
    context 'missing benefit_group_assignment' do
      it 'should return a failure with a message' do
        result = subject.call({benefit_group_assignment: nil})
        expect(result.failure).to eq('Missing Key.')
      end
    end

    context 'invalid benefit group assignment' do
      it 'should return a failure with a message' do
        result = subject.call({benefit_group_assignment: double("Person"), options: {}})
        expect(result.failure).to eq('Not a valid BenefitGroupAssignment object.')
      end

      it 'should return a failure with a message if end_on is blank' do
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {}})
        expect(result.failure).to eq('End on must be present for the given benefit group assignment.')
      end

      it 'should return a failure with a message if benefit_package is blank' do
        benefit_group_assignment.update_attribute("benefit_package_id", nil)
        benefit_group_assignment.update_attributes(end_on: initial_benefit_package.start_on + 3.months)
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {}})
        expect(result.failure).to eq('Benefit Package must be present for this benefit group assignment.')
      end

      it 'should return a failure if end on is less than start on' do
        benefit_group_assignment.update_attribute("end_on", benefit_group_assignment.start_on - 1.month)
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {}})
        expect(result.failure).to eq('Invalid Benefit Group. End on cannot occur before the start on.')
      end
    end

    context 'overlapping benefit group assignments' do
      let(:new_benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: initial_benefit_package, census_employee: census_employee)}

      before do
        benefit_group_assignment.update_attributes(end_on: initial_benefit_package.start_on + 3.months - 1.day)
      end

      it 'should return error message if no benefit package is found' do
        initial_application.update_attributes(effective_period: benefit_group_assignment.start_on..benefit_group_assignment.end_on)
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: nil}})
        expect(result.failure).to eq('Unable to fetch new benefit package')
      end

      it 'should return error message if overlapping bga exists' do
        new_benefit_group_assignment.update_attributes(start_on: benefit_group_assignment.end_on.next_day)
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: initial_benefit_package}})
        expect(result.failure).to eq('Overlapping benefit group assignments present')
      end
    end

    context 'is_eligible_to_reinstate_bga?' do
      before do
        benefit_group_assignment.update_attributes(end_on: initial_benefit_package.benefit_application.start_on + 3.months - 1.day)
        initial_benefit_package.benefit_application.update_attributes(effective_period: benefit_group_assignment.start_on..benefit_group_assignment.end_on)
      end

      it 'should return error message if overlapping bga exists' do
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: initial_benefit_package}})
        expect(result.failure).to eq('New benefit group assignment cannot fall outside the plan year')
      end
    end
  end

  context 'Success' do

    let(:reinstated_benefit_package) { initial_benefit_package }

    context 'if previous benefit group assignment is in terminated or termination pending status' do

      before do
        benefit_group_assignment.update_attributes(end_on: initial_benefit_package.benefit_application.start_on + 3.months - 1.day)
        reinstated_benefit_package.benefit_application.update_attributes(effective_period: (benefit_group_assignment.end_on + 1.day)..reinstated_benefit_package.end_on)
      end

      it 'should create new benefit group assignment for census employee' do
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}})
        expect(result.success).to be_a(BenefitGroupAssignment)
      end

      it 'should return success object' do
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}})
        expect(result).to be_a(Dry::Monads::Result::Success)
      end

      it 'should create bga for census employee' do
        expect(census_employee.benefit_group_assignments.count).to eq 1
        subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}})
        expect(census_employee.benefit_group_assignments.count).to eq 2
      end

      it "reinstated bga start date == old bga end date + 1" do
        reinstated_bga = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}}).success
        expect(reinstated_bga.start_on).to eq benefit_group_assignment.end_on.next_day
        expect(reinstated_bga.activated_at).to eq TimeKeeper.datetime_of_record
      end
    end

    context 'if previous benefit group assignment is canceled' do

      before do
        benefit_group_assignment.update_attributes(end_on: reinstated_benefit_package.benefit_application.start_on)
      end

      it 'should create new benefit group assignment for census employee' do
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}})
        expect(result.success).to be_a(BenefitGroupAssignment)
      end

      it 'should return success object' do
        result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}})
        expect(result).to be_a(Dry::Monads::Result::Success)
      end

      it 'should create bga for census employee' do
        expect(census_employee.benefit_group_assignments.count).to eq 1
        subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}})
        expect(census_employee.benefit_group_assignments.count).to eq 2
      end

      it 'newly create bga for census employee should have the same start as benefit package start on' do
        expect(census_employee.benefit_group_assignments.count).to eq 1
        reinstated_bga = subject.call({benefit_group_assignment: benefit_group_assignment, options: {benefit_package: reinstated_benefit_package}}).success
        new_bga = census_employee.benefit_group_assignments.by_benefit_package(reinstated_benefit_package).detect(&:is_active?)
        expect(new_bga.end_on).to eq nil

        expect(reinstated_bga.start_on).to eq benefit_group_assignment.start_on
        expect(reinstated_bga.activated_at).to eq TimeKeeper.datetime_of_record

      end
    end

  end
end
