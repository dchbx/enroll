FactoryGirl.define do
  factory(:applicant, :class => FinancialAssistance::Applicant) do
    association :application

    is_active true
    is_ia_eligible false
    is_medicaid_chip_eligible false
    is_without_assistance false
    is_totally_ineligible false
    has_fixed_address true
    tax_filer_kind "tax_filer"
  end
end
