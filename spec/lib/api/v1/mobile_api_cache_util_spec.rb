require "rails_helper"
require 'support/brady_bunch'
require 'lib/api/v1/support/mobile_employer_data'
require 'lib/api/v1/support/mobile_employee_data'

RSpec.describe Api::V1::Mobile::CacheUtil, dbclean: :after_each do
  include_context 'employer_data'
  include Api::V1::Mobile::CacheUtil

  context "Caching" do
    include_context 'employee_data'

    it 'caches plans and benefit groups' do
      cache = plan_and_benefit_group [ce_employee], employer_profile_salon
      expect(cache).to include(:employees_benefits, :grouped_bga_enrollments)
      expect(cache[:employees_benefits]).to be_a_kind_of Array
      expect(cache[:employees_benefits].first).to be_a_kind_of Hash
      expect(cache[:employees_benefits].first.keys.size).to eq 2

      expect(cache[:employees_benefits].first).to include(ce_employee.id.to_s, :benefit_group_assignments)
      expect(cache[:employees_benefits].first[ce_employee.id.to_s]).to be_a_kind_of CensusEmployee
      expect(cache[:employees_benefits].first[:benefit_group_assignments]).to be_a_kind_of Array
      expect(cache[:grouped_bga_enrollments]).to be_a_kind_of Hash
      expect(cache[:grouped_bga_enrollments].first.pop.first).to be_a_kind_of HbxEnrollment
    end

  end

end

