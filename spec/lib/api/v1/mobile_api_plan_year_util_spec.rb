require "rails_helper"
require 'lib/api/v1/support/mobile_employer_data'

RSpec.describe Api::V1::Mobile::PlanYearUtil, dbclean: :after_each do
  include_context 'employer_data'

  context 'Plan' do

    it 'should check if the plan is in open enrollment' do
      plan_year = Api::V1::Mobile::PlanYearUtil.new plan_year: employer_profile_cafe.show_plan_year, as_of: Date.parse('2016-12-05')
      expect(plan_year.open_enrollment?).to be_truthy

      plan_year = Api::V1::Mobile::PlanYearUtil.new plan_year: employer_profile_cafe.show_plan_year, as_of: Date.parse('2014-12-05')
      expect(plan_year.open_enrollment?).to be_falsey

      plan_year = Api::V1::Mobile::PlanYearUtil.new plan_year: employer_profile_cafe.show_plan_year
      expect(plan_year.open_enrollment?).to be_falsey

      allow(employer_profile_cafe.show_plan_year).to receive_message_chain(:employer_profile, :census_employees, :count).and_return(99)
      plan_year = Api::V1::Mobile::PlanYearUtil.new plan_year: employer_profile_cafe.show_plan_year, as_of: Date.parse('2016-12-05')
      expect(plan_year.open_enrollment?).to be_truthy

      allow(employer_profile_cafe.show_plan_year).to receive_message_chain(:employer_profile, :census_employees, :count).and_return(100)
      plan_year = Api::V1::Mobile::PlanYearUtil.new plan_year: employer_profile_cafe.show_plan_year, as_of: Date.parse('2016-12-05')
      expect(plan_year.open_enrollment?).to be_falsey
    end

    it 'should return plan offerings' do
      plan_year = Api::V1::Mobile::PlanYearUtil.new plan_year: employer_profile_cafe.show_plan_year, as_of: Date.parse('2016-12-05')
      plan_offerings = plan_year.plan_offerings
      expect(plan_offerings).to be_a_kind_of Array
      expect(plan_offerings.size).to eq 2

      plan_offering = plan_offerings.pop
      expect(plan_offering).to include(:benefit_group_name, :eligibility_rule, :health, :dental)
      expect(plan_offering[:benefit_group_name]).to eq 'white collar'
      expect(plan_offering[:eligibility_rule]).to eq 'First of the month following or coinciding with date of hire'

      health = plan_offering[:health]
      expect(health).to include(:reference_plan_name, :reference_plan_HIOS_id, :carrier_name, :plan_type, :metal_level,
                                :plan_option_kind, :employer_contribution_by_relationship, :elected_dental_plans,
                                :estimated_employer_max_monthly_cost, :estimated_plan_participant_min_monthly_cost,
                                :estimated_plan_participant_max_monthly_cost, :plans_by, :plans_by_summary_text)
      expect(health[:reference_plan_HIOS_id].split('').length).to eq 17
      expect(health[:carrier_name]).to eq 'United Health Care'
      expect(health[:plan_type]).to eq 'HMO'
      expect(health[:metal_level]).to eq 'Silver'
      expect(health[:plan_option_kind]).to eq 'single_plan'
      expect(health[:plans_by]).to eq 'A Single Plan'
      expect(health[:plans_by_summary_text]).to eq 'Reference Plan Only'

      by_relationship = health[:employer_contribution_by_relationship]
      expect(by_relationship).to include('employee', 'spouse', 'domestic_partner', 'child_under_26',
                                         'disabled_child_26_and_over', 'child_26_and_over')
      expect(by_relationship['employee']).to eq 80.0
      expect(by_relationship['spouse']).to eq 40.0
      expect(by_relationship['domestic_partner']).to eq 40.0
      expect(by_relationship['child_under_26']).to eq 40.0
      expect(by_relationship['disabled_child_26_and_over']).to eq 40.0


      dental = plan_offering[:dental]
      expect(dental).to include(:reference_plan_name, :reference_plan_HIOS_id, :carrier_name, :plan_type, :metal_level,
                                :plan_option_kind, :employer_contribution_by_relationship, :elected_dental_plans,
                                :estimated_employer_max_monthly_cost, :estimated_plan_participant_min_monthly_cost,
                                :estimated_plan_participant_max_monthly_cost, :plans_by, :plans_by_summary_text)
      expect(dental[:reference_plan_HIOS_id].split('').length).to eq 17
      expect(dental[:carrier_name]).to eq 'United Health Care'
      expect(dental[:plan_type]).to eq 'HMO'
      expect(dental[:metal_level]).to eq 'Silver'
      expect(dental[:plan_option_kind]).to eq 'single_plan'
      expect(dental[:plans_by]).to eq 'Custom (1 Plans)'
      expect(dental[:plans_by_summary_text]).to eq 'Custom (1 Plans)'

      by_relationship = dental[:employer_contribution_by_relationship]
      expect(by_relationship).to include('employee', 'spouse', 'domestic_partner', 'child_under_26',
                                         'disabled_child_26_and_over', 'child_26_and_over')
      expect(by_relationship['employee']).to eq 49.0
      expect(by_relationship['spouse']).to eq 40.0
      expect(by_relationship['domestic_partner']).to eq 40.0
      expect(by_relationship['disabled_child_26_and_over']).to eq 40.0
    end

  end

end