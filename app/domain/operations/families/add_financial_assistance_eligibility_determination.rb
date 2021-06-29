# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class AddFinancialAssistanceEligibilityDetermination
      send(:include, Dry::Monads[:result, :do])

      def call(params:)
        values = yield validate(params) #application_contract
        family = yield find_family(values[:family_id])
        result = yield add_determination(family, values)

        Success(result)
      end

      private

      def validate(params)
        contract_result = Validators::Families::EligibilityDeterminationContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: family_id)
      end

      def add_determination(family, values)
        deactivate_latest_tax_households(values)
        benchmark_plan_id = values[:benchmark_product_id]
        values[:eligibility_determinations].each do |faa_ed|
          th = family.active_household.tax_households.build(hbx_assigned_id: faa_ed["hbx_assigned_id"],
                                                            effective_starting_on: faa_ed["effective_starting_on"],
                                                            is_eligibility_determined: faa_ed["is_eligibility_determined"])
          applicants = values[:applicants].select{|app| app["eligibility_determination_id"] == faa_ed["_id"]}
          applicants.each do |applicant| #TODO: select instead
            create_tax_household_members(family, th, applicant)
          end

          build_eligibility_determinations(th, faa_ed, benchmark_plan_id)
        end
        family.active_household.save!
        update_family_attributes(family, values[:integrated_case_id])

        Success(family)
      end

      def build_eligibility_determinations(tax_household, faa_ed, benchmark_plan_id)
        max_aptc = Money.new(faa_ed["max_aptc"]["cents"], 'USD')
        verified_aptc = max_aptc.to_f > 0.00 ? max_aptc.to_f : 0.00
        tax_household.eligibility_determinations.build(
          benchmark_plan_id: benchmark_plan_id,
          max_aptc: verified_aptc,
          csr_percent_as_integer: faa_ed["csr_percent_as_integer"],
          determined_at: faa_ed["determined_at"],
          aptc_csr_annual_household_income: faa_ed["aptc_csr_annual_household_income"],
          aptc_annual_income_limit: faa_ed["aptc_annual_income_limit"],
          csr_annual_income_limit: faa_ed["csr_annual_income_limit"],
          source: faa_ed["source"]
        ).save
      end

      def create_tax_household_members(family, tax_household, applicant)
        family_member = fetch_family_member_from_applicant(family, applicant)

        return Failure('Unable to find family member') if family_member.blank?

        tax_household.tax_household_members.build(
          applicant_id: family_member.id,
          medicaid_household_size: applicant["medicaid_household_size"],
          magi_medicaid_category: applicant["magi_medicaid_category"],
          magi_as_percentage_of_fpl: applicant["magi_as_percentage_of_fpl"],
          magi_medicaid_monthly_income_limit: applicant["magi_medicaid_monthly_income_limit"],
          magi_medicaid_monthly_household_income: applicant["magi_medicaid_monthly_household_income"],
          is_without_assistance: applicant["is_without_assistance"],
          is_ia_eligible: applicant["is_ia_eligible"],
          is_medicaid_chip_eligible: applicant["is_medicaid_chip_eligible"],
          is_non_magi_medicaid_eligible: applicant["is_non_magi_medicaid_eligible"],
          is_totally_ineligible: applicant["is_totally_ineligible"]
        )
      end

      def fetch_family_member_from_applicant(family, applicant)
        person = Person.where(hbx_id: applicant["person_hbx_id"]).first
        family.family_members.where(person_id: person.id).first
      end

      def deactivate_latest_tax_households(values)
        primary_applicant = values[:applicants].select{|app| app["is_primary_applicant"]}.first
        ed = values[:eligibility_determinations].select{|ed| ed["_id"] == primary_applicant["eligibility_determination_id"]}.first
        Operations::Households::DeactivateFinancialAssistanceEligibility.new.call(params: {family_id: values[:family_id], date: ed["effective_starting_on"]})
      end

      def update_family_attributes(family, case_id)
        family.e_case_id = case_id
        Success(family.save!)
      end
    end
  end
end
