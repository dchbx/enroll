# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::FinancialAssistance::ApplicationHelper, :type => :helper, dbclean: :after_each do
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: BSON::ObjectId.new) }
  let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      eligibility_determination_id: ed.id,
                      is_ia_eligible: true,
                      first_name: 'Test',
                      last_name: 'Test10')
  end

  describe 'total_aptc_across_eligibility_determinations' do
    before do
      @result = helper.total_aptc_across_eligibility_determinations(application.id)
    end

    it 'should return the sum of all aptcs' do
      expect(@result).to eq(225.13)
    end
  end

  describe 'eligible_applicants' do
    before do
      @result = helper.eligible_applicants(application.id, :is_ia_eligible)
    end

    it 'should return array of names of the applicants' do
      expect(@result).to include('Test Test10')
    end
  end

  describe 'any_csr_ineligible_applicants?' do
    before do
      @result = helper.any_csr_ineligible_applicants?(application.id)
    end

    it 'should return false as the only applicant is eligible for CSR' do
      expect(@result).to be_falsy
    end
  end
end
