require "rails_helper"
require 'lib/api/v1/support/mobile_employer_data'

RSpec.describe Api::V1::Mobile::FamilyUtil, dbclean: :after_each do
  include_context 'employer_data'

  context 'Family' do

    it 'should return HBX enrollments' do
      family = Api::V1::Mobile::FamilyUtil.new benefit_group_assignment_ids: [benefit_group_assignment.id], aasm_states: ['coverage_selected']
      expect(family.hbx_enrollments).to be_a_kind_of Array
      expect(family.hbx_enrollments.size).to eq 4
      expect(family.hbx_enrollments.pop).to be_a_kind_of HbxEnrollment
    end

  end

end