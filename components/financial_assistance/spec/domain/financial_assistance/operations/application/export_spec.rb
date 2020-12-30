# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Application::Export, dbclean: :after_each do
  let!(:application) do
    FactoryBot.build(:financial_assistance_application, :with_applicants, aasm_state: 'draft')
  end
  let!(:create_elibility_determinations) do
    application.eligibility_determinations.build({
                                                    max_aptc: 0,
                                                    csr_percent_as_integer: 0,
                                                    aptc_csr_annual_household_income: 0,
                                                    aptc_annual_income_limit: 0,
                                                    csr_annual_income_limit: 0,
                                                    hbx_assigned_id: 10_001
                                                  })
  end
  let!(:set_terms_on_application) do
    application.assign_attributes({
                                    :medicaid_terms => true,
                                    :submission_terms => true,
                                    :medicaid_insurance_collection_terms => true,
                                    :report_change_terms => true
                                  })
  end

  let(:result) { subject.call(application: application) }

  it 'exports payload successfully' do
    expect(result.success?).to be_truthy
  end

  it 'exports a payload' do
    expect(result.success).to be_a_kind_of(Hash)
  end
end