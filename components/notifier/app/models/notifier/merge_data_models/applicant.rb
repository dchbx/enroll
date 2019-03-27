module Notifier
  class MergeDataModels::Applicant
    include Virtus.model

    attribute :first_name, String
    attribute :last_name, String
    attribute :age, Integer
    attribute :is_medicaid_chip_eligible, Boolean
    attribute :is_ia_eligible, Boolean
    attribute :indian_conflict, Boolean
    attribute :is_non_magi_medicaid_eligible, Boolean
    attribute :is_without_assistance, Boolean
    attribute :magi_medicaid_monthly_income_limit, Money
    attribute :has_access_to_affordable_coverage, Boolean
    attribute :immigration_unverified, Array[String]
    attribute :no_aptc_because_of_income, Boolean
    attribute :no_csr_because_of_income, Boolean
    attribute :is_totally_ineligible, Boolean
    attribute :reason_for_ineligibility, Array[String]


    def self.stubbed_object
      Notifier::MergeDataModels::Applicant.new({
        first_name: 'Test',
        last_name: 'Dependent',
        age: 26
        tax_household: append_tax_households(applicant.tax_household),
      # first_name: applicant.person.first_name.titleize,
      # last_name: applicant.person.last_name.titleize,
      # full_name: applicant.person.full_name.titleize,
      # age: applicant.person.age_on(TimeKeeper.date_of_record),
      is_medicaid_chip_eligible: applicant.is_medicaid_chip_eligible,
      is_ia_eligible: applicant.is_ia_eligible,
      indian_conflict: applicant.person.consumer_role.indian_conflict?,
      is_non_magi_medicaid_eligible: applicant.is_non_magi_medicaid_eligible,
      is_without_assistance: applicant.is_without_assistance,
      magi_medicaid_monthly_income_limit: applicant.magi_medicaid_monthly_income_limit,
      has_access_to_affordable_coverage: applicant.benefits.where(:kind => "is_eligible").present?,
      immigration_unverified: applicant.person.consumer_role.outstanding_verification_types.include?("Immigration status"),
      no_aptc_because_of_income: (applicant.preferred_eligibility_determination.aptc_csr_annual_household_income > applicant.preferred_eligibility_determination.aptc_annual_income_limit) ? true : false,
      no_csr_because_of_income: (applicant.preferred_eligibility_determination.aptc_csr_annual_household_income > applicant.preferred_eligibility_determination.csr_annual_income_limit) ? true : false,
      is_totally_ineligible: applicant.is_totally_ineligible,
      reason_for_ineligibility: reason_for_ineligibility
      })
    end
  end
end