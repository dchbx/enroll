FactoryGirl.define do
  factory :eligibility_determination do
    tax_household
    determined_on TimeKeeper.datetime_of_record
    determined_at TimeKeeper.datetime_of_record
    max_aptc  225.13
    csr_percent_as_integer 94
    csr_eligibility_kind "csr_94"
    premium_credit_strategy_kind "allocated_lump_sum_credit"
    e_pdc_id "3110344"
    source "Curam"
  end
end
