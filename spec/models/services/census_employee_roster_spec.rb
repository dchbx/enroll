# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits.rb"
include ActionView::Helpers::NumberHelper

RSpec.describe Services::CensusEmployeeRoster, :dbclean => :after_each do
  describe 'Employer Flow' do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'
    include_context 'setup employees with benefits'

    let!(:health_products) do
      create_list(:benefit_markets_products_health_products_health_product,
                  5, :with_renewal_product, :with_issuer_profile,
                  application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
                  product_package_kinds: [:single_issuer, :metal_level, :single_product],
                  assigned_site: site,
                  service_area: service_area,
                  renewal_service_area: renewal_service_area,
                  metal_level_kind: :gold)
    end
    let(:effective_period_start_on) {TimeKeeper.date_of_record.end_of_month + 1.day - 2.month}
    let(:current_effective_date) {effective_period_start_on}
    let(:effective_period_end_on) {effective_period_start_on + 1.year - 1.day}
    let(:effective_period) {effective_period_start_on..effective_period_end_on}
    let(:benefit_pkgs) {initial_application.benefit_packages}

    let(:census_dependents_attributes) do
      {:first_name => 'David', :middle_name => '', :last_name => 'Chan', :dob => TimeKeeper.date_of_record - 17.years, gender: 'female', :employee_relationship => 'child_under_26', :ssn => 678453261}
    end

    let(:census_dependents_attributes2) do
      {:first_name => 'Lara', :middle_name => '', :last_name => 'Chan', :dob => TimeKeeper.date_of_record - 40.years, gender: 'male', :employee_relationship => 'spouse', :ssn => 657482918}
    end

    before :each do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(100.0)
      census_employees.first.census_dependents.new(census_dependents_attributes)
      census_employees.first.save!
      abc_profile.reload
    end

    subject {Services::CensusEmployeeRoster.new(abc_profile, {action: 'download', feature: 'employer'})}

    context 'total_premium' do
      it 'should return total health and dental premium' do
        expect(subject.total_premium(benefit_pkgs)).to eq ['$500.00', '$0.00']
      end
    end

    context 'to_csv' do
      it 'should generate csv' do
        csv_string = subject.to_csv
        csv_table = CSV.parse(csv_string, :headers => true, :skip_lines => /^DC Health Link Employee Census Template/)
        expect(csv_table.count).to eq 5 #number of census employee rows without header
        expect(csv_table.headers.count).to eq 28 #header columns count, changes with change in number of dependents
      end
    end

    context 'benefit_group_assignment_details' do
      it 'should return array for existing active assignments' do
        bga = subject.benefit_group_assignment_details(census_employees.first)
        expect(bga).to eq ['first benefit package', 'dental:   health: ', initial_application.start_on]
      end
    end
  end

  describe 'BQT Flow' do
    before :each do
      allow(Caches::PlanDetails).to receive(:lookup_rate).and_return 78
    end

    include_context 'set up broker agency profile for BQT, by using configuration settings'

    let!(:profile) {plan_design_proposal.profile}
    let!(:census_employee) {plan_design_census_employee}
    let!(:plan_year) {benefit_application}

    subject {Services::CensusEmployeeRoster.new(profile, {action: 'download', feature: 'bqt'})}

    context 'total_premium' do
      it 'should return total employer contribution for health and dental' do
        health_premium = subject.total_premium(nil)[0]
        dental_premium = subject.total_premium(nil)[1]
        expect([health_premium, dental_premium]).to eq ['$62.40', nil]
      end
    end

    context 'to_csv' do
      it 'should generate csv' do
        csv_string = subject.to_csv
        csv_table = CSV.parse(csv_string, :headers => true, :skip_lines => /^DC Health Link Employee Census Template/)
        expect(csv_table.count).to eq 1 #number of census employee rows without header
        expect(csv_table.headers.count).to eq 25 #header columns count, changes with change in number of dependents
      end
    end

    context 'benefit_group_assignment_details' do
      it 'should return array of nil for no assignments' do
        bga = subject.benefit_group_assignment_details(census_employee)
        expect(bga).to eq [nil, nil, nil]
      end
    end
  end
end
