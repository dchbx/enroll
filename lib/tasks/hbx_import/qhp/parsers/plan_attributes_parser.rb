module Parser
  class PlanAttributesParser
    include HappyMapper

    tag 'planAttributes'

    element :standard_component_id, String, tag: 'standardComponentID'
    element :plan_marketing_name, String, tag: 'planMarketingName'
    element :hios_product_id, String, tag: 'hiosProductID'
    element :ehb_percent_premium, String, tag: 'ehbPercentPremium'
    element :hpid, String, tag: 'hpid'
    element :network_id, String, tag: 'networkID'
    element :service_area_id, String, tag: 'serviceAreaID'
    element :formulary_id, String, tag: 'formularyID'
    element :is_new_plan, String, tag: 'isNewPlan'
    element :plan_type, String, tag: 'planType'
    element :metal_level, String, tag: 'metalLevel'
    element :unique_plan_design, String, tag: 'uniquePlanDesign'
    element :qhp_or_non_qhp, String, tag: 'qhpOrNonQhp'
    element :insurance_plan_pregnancy_notice_req_ind, String, tag: 'insurancePlanPregnancyNoticeReqInd'
    element :is_specialist_referral_required, String, tag: 'isSpecialistReferralRequired'
    element :health_care_specialist_referral_type, String, tag: 'healthCareSpecialistReferralType'
    element :insurance_plan_benefit_exclusion_text, String, tag: 'insurancePlanBenefitExclusionText'
    element :indian_plan_variation, String, tag: 'indianPlanVariation'
    element :hsa_eligibility, String, tag: 'hsaEligibility'
    element :employer_hsa_hra_contribution_indicator, String, tag: 'employerHSAHRAContributionIndicator'
    element :emp_contribution_amount_for_hsa_or_hra, String, tag: 'empContributionAmountForHSAOrHRA'
    element :child_only_offering, String, tag: 'childOnlyOffering'
    element :child_only_plan_id, String, tag: 'childOnlyPlanID'
    element :is_wellness_program_offered, String, tag: 'isWellnessProgramOffered'
    element :is_disease_mgmt_programs_offered, String, tag: 'isDiseaseMgmtProgramsOffered'
    element :ehb_apportionment_for_pediatric_dental, String, tag: 'ehbApportionmentForPediatricDental'
    element :guaranteed_vs_estimated_rate, String, tag: 'guaranteedVsEstimatedRate'
    element :maximum_coinsurance_for_specialty_drugs, String, tag: 'maximumCoinsuranceForSpecialtyDrugs'
    element :max_num_days_for_charging_inpatient_copay, String, tag: 'maxNumDaysForChargingInpatientCopay'
    element :begin_primary_care_deductible_or_coinsurance_after_set_number_copays, String, tag: 'beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays'
    element :begin_primary_care_cost_sharing_after_set_number_visits, String, tag: 'beginPrimaryCareCostSharingAfterSetNumberVisits'
    element :plan_effective_date, String, tag: 'planEffectiveDate'
    element :plan_expiration_date, String, tag: 'planExpirationDate'
    element :out_of_country_coverage, String, tag: 'outOfCountryCoverage'
    element :out_of_country_coverage_description, String, tag: 'outOfCountryCoverageDescription'
    element :out_of_service_area_coverage, String, tag: 'outOfServiceAreaCoverage'
    element :out_of_service_area_coverage_description, String, tag: 'outOfServiceAreaCoverageDescription'
    element :national_network, String, tag: 'nationalNetwork'
    element :summary_benefit_and_coverage_url, String, tag: 'summaryBenefitAndCoverageURL'
    element :enrollment_payment_url, String, tag: 'enrollmentPaymentURL'
    element :plan_brochure, String, tag: 'planBrochure'

    def to_hash
      {
        standard_component_id: standard_component_id.gsub(/\n/,'').strip,
        plan_marketing_name: plan_marketing_name.gsub(/\n/,'').strip,
        hios_product_id: hios_product_id.gsub(/\n/,'').strip,
        hpid: hpid.gsub(/\n/,'').strip,
        network_id: network_id.gsub(/\n/,'').strip,
        service_area_id: service_area_id.gsub(/\n/,'').strip,
        formulary_id: formulary_id.gsub(/\n/,'').strip,
        is_new_plan: is_new_plan.gsub(/\n/,'').strip,
        plan_type: plan_type.gsub(/\n/,'').strip,
        metal_level: metal_level.gsub(/\n/,'').strip,
        unique_plan_design: unique_plan_design.gsub(/\n/,'').strip,
        qhp_or_non_qhp: qhp_or_non_qhp.gsub(/\n/,'').strip,
        insurance_plan_pregnancy_notice_req_ind: insurance_plan_pregnancy_notice_req_ind.gsub(/\n/,'').strip,
        is_specialist_referral_required: is_specialist_referral_required.gsub(/\n/,'').strip,
        health_care_specialist_referral_type: health_care_specialist_referral_type.gsub(/\n/,'').strip,
        insurance_plan_benefit_exclusion_text: insurance_plan_benefit_exclusion_text.gsub(/\n/,'').strip,
        indian_plan_variation: indian_plan_variation.gsub(/\n/,'').strip,
        hsa_eligibility: (hsa_eligibility.gsub(/\n/,'').strip rescue ""),
        employer_hsa_hra_contribution_indicator: (employer_hsa_hra_contribution_indicator.gsub(/\n/,'').strip  rescue ""),
        emp_contribution_amount_for_hsa_or_hra: (emp_contribution_amount_for_hsa_or_hra.gsub(/\n/,'').strip  rescue ""),
        child_only_offering: child_only_offering.gsub(/\n/,'').strip,
        child_only_plan_id: child_only_plan_id.gsub(/\n/,'').strip,
        is_wellness_program_offered: is_wellness_program_offered.gsub(/\n/,'').strip,
        is_disease_mgmt_programs_offered: is_disease_mgmt_programs_offered.gsub(/\n/,'').strip,
        ehb_apportionment_for_pediatric_dental: ehb_apportionment_for_pediatric_dental.gsub(/\n/,'').strip,
        guaranteed_vs_estimated_rate: guaranteed_vs_estimated_rate.gsub(/\n/,'').strip,
        maximum_coinsurance_for_specialty_drugs: (maximum_coinsurance_for_specialty_drugs.gsub(/\n/,'').strip rescue ""),
        max_num_days_for_charging_inpatient_copay: (max_num_days_for_charging_inpatient_copay.gsub(/\n/,'').strip rescue ""),
        begin_primary_care_deductible_or_coinsurance_after_set_number_copays: (begin_primary_care_deductible_or_coinsurance_after_set_number_copays.gsub(/\n/,'').strip rescue ""),
        begin_primary_care_cost_sharing_after_set_number_visits: (begin_primary_care_cost_sharing_after_set_number_visits.gsub(/\n/,'').strip rescue ""),
        plan_effective_date: plan_effective_date.gsub(/\n/,'').strip,
        plan_expiration_date: plan_expiration_date.gsub(/\n/,'').strip,
        out_of_country_coverage: out_of_country_coverage.gsub(/\n/,'').strip,
        out_of_country_coverage_description: out_of_country_coverage_description.gsub(/\n/,'').strip,
        out_of_service_area_coverage: out_of_service_area_coverage.gsub(/\n/,'').strip,
        out_of_service_area_coverage_description: out_of_service_area_coverage_description.gsub(/\n/,'').strip,
        national_network: national_network.gsub(/\n/,'').strip,
        ehb_percent_premium: (ehb_percent_premium.present? ? ehb_percent_premium.gsub(/\n/,'').strip : ""),
        summary_benefit_and_coverage_url: (summary_benefit_and_coverage_url.gsub(/\n/,'').strip rescue ""),
        enrollment_payment_url: enrollment_payment_url.gsub(/\n/,'').strip,
        plan_brochure: (plan_brochure.gsub(/\n/,'').strip rescue "")
      }
    end
  end
end