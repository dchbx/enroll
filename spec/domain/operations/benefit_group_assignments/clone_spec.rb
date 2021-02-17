# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::BenefitGroupAssignments::Clone, :type => :model, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup renewal application"

  let(:benefit_application)    { initial_application }
  let(:employer_profile)       {  abc_profile }
  let(:initial_benefit_package) { initial_application.benefit_packages.first }
  let(:renewal_benefit_package) { renewal_application.benefit_packages.first }
  let(:census_employee)      { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
  let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: initial_benefit_package, start_on: initial_benefit_package.start_on,  census_employee: census_employee)}


  context 'missing keys' do
    context 'missing additional options' do
      before do
        @result = subject.call({options: {}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing Keys.')
      end
    end

    context 'missing benefit_group_assignment' do
      before do
        @result = subject.call({benefit_group_assignment: benefit_group_assignment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing Keys.')
      end
    end
  end

  context 'invalid benefit group assignment' do
    before do
      @result = subject.call({benefit_group_assignment: double("Person"), options: {}})
    end

    it 'should return a failure with a message' do
      expect(@result.failure).to eq('Not a valid BenefitGroupAssignment object.')
    end
  end

  context 'invalid options' do
    before do
      @result = subject.call({benefit_group_assignment: benefit_group_assignment, options: []})
    end

    it 'should return a failure with a message' do
      expect(@result.failure).to eq("Invalid options's value. Should be a Hash.")
    end
  end

  context 'invalid options' do
    before do
      @result = subject.call({benefit_group_assignment: benefit_group_assignment, options: []})
    end

    it 'should return a failure with a message' do
      expect(@result.failure).to eq("Invalid options's value. Should be a Hash.")
    end
  end

  context 'Success' do
    before do
      initial_application.terminate_enrollment!
      initial_application.update_attributes!(terminated_on: initial_application.end_on - 2.months)
      benefit_group_assignment.update_attributes!(end_on: initial_benefit_package.end_on - 2.months)
      @result = subject.call({benefit_group_assignment: benefit_group_assignment, options: {start_on: benefit_group_assignment.end_on.next_day, benefit_package_id: renewal_benefit_package.id}})
    end

    it 'should return a benefit group assignment object' do
      expect(@result.success).to be_a(BenefitGroupAssignment)
    end

    it 'should return success object' do
      expect(@result).to be_a(Dry::Monads::Result::Success)
    end

    it 'should return true' do
      expect(@result.success).to be_truthy
    end
  end
end