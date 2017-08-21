module PdfTemplates
  class Individual
    include Virtus.model

    attribute :first_name, String
    attribute :full_name, String
    attribute :age, String
    attribute :ssn_verified, Boolean, :default => false
    attribute :citizenship_verified, Boolean, :default => false
    attribute :immigration_unverified, Boolean
    attribute :citizen_status, String
    attribute :tax_household, PdfTemplates::TaxHousehold
    attribute :documents_due_date, Date
    # attribute :household_size, String
    attribute :projected_amount, String
    attribute :taxhh_count, String
    attribute :tax_status, String
    attribute :filer_type, String
    attribute :uqhp_reason, String
    attribute :reason_for_ineligibility, Array[String]
    attribute :mec, String
    attribute :residency_verified, Boolean, :default => false
    attribute :indian_conflict, Boolean, :default => false
    attribute :incarcerated, Boolean, :default => false

    attribute :magi_medicaid_monthly_income_limit, Integer
    attribute :magi_as_percentage_of_fpl, Integer

    attribute :is_medicaid_chip_eligible, Boolean, :default => false
    attribute :is_ia_eligible, Boolean, :default => false
    attribute :is_non_magi_medicaid_eligible, Boolean, :default => false
    attribute :is_without_assistance, Boolean, :default => false
    attribute :is_totally_ineligible, Boolean, :default => false
    attribute :no_aptc_because_of_income, Boolean, :default => false
    attribute :no_aptc_because_of_tax, Boolean, :default => false
    attribute :no_csr_because_of_income, Boolean, :default => false
    attribute :no_csr_because_of_tax, Boolean, :default => false
    attribute :has_access_to_affordable_coverage, Boolean, :default => false

    # attribute :ineligible_members, Array[String]
    # attribute :ineligible_members_due_to_residency, Array[String]
    # attribute :ineligible_members_due_to_incarceration, Array[String]
    # attribute :ineligible_members_due_to_immigration, Array[String]
    # attribute :active_members, Array[String]
    # attribute :inconsistent_members, Array[String]
    # attribute :eligible_immigration_status_members, Array[String]
    # attribute :members_with_more_plans, Array[String]
    # attribute :indian_tribe_members, Array[String]
    # attribute :unverfied_resident_members, Array[String]
    # attribute :unverfied_citizenship_members, Array[String]
    # attribute :unverfied_ssn_members, Array[String]


    def verified
      (ssn_verified && citizenship_verified && residency_verified && !indian_conflict)
    end
  end
end
