require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','sbc_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','maximum_out_of_pockets_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','deductible_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','service_visits_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','hsa_parser')

module Parser
  class CostShareVarianceParser
    include HappyMapper

    tag 'costShareVariance'

    element :hios_plan_and_variant_id, String, tag: "planId"
    element :plan_marketing_name, String, tag: "planMarketingName"
    element :plan_variant_marketing_name, String, tag: "planVariantMarketingName"
    element :metal_level, String, tag: "metalLevel"
    element :csr_variation_type, String, tag: "csrVariationType"
    element :issuer_actuarial_value, String, tag: "issuerActuarialValue"
    element :av_calculator_output_number, String, tag: "avCalculatorOutputNumber"
    element :medical_and_drug_deductibles_integrated, String, tag: "medicalAndDrugDeductiblesIntegrated"
    element :medical_and_drug_max_out_of_pocket_integrated, String, tag: "medicalAndDrugMaxOutOfPocketIntegrated"
    element :multiple_provider_tiers, String, tag: "multipleProviderTiers"
    element :first_tier_utilization, String, tag: "firstTierUtilization"
    element :second_tier_utilization, String, tag: "secondTierUtilization"
    element :default_copay_in_network, String, tag: "defaultCopayInNetwork"
    element :default_copay_out_of_network, String, tag: "defaultCopayOutOfNetwork"
    element :default_co_insurance_in_network, String, tag: "defaultCoInsuranceInNetwork"
    element :default_co_insurance_out_of_network, String, tag: "defaultCoInsuranceOutOfNetwork"

    has_one :sbc_attributes, Parser::SbcParser, tag: "sbc"
    has_many :maximum_out_of_pockets_attributes, Parser::MaximumOutOfPocketsParser, tag: "moop", deep: true
    has_one :deductible_attributes, Parser::DeductibleParser, tag: "planDeductible", deep:true
    has_many :service_visits_attributes, Parser::ServiceVisitsParser, tag: "serviceVisit", deep: true
    has_one :hsa_attributes, Parser::HsaParser, tag: "hsa", deep: true

    def to_hash
      response = {
        cost_share_variance_attributes: {
          hios_plan_and_variant_id: hios_plan_and_variant_id.gsub(/\n/,'').strip,
          plan_marketing_name: plan_marketing_name.present? ? plan_marketing_name.gsub(/\n/,'').strip : plan_variant_marketing_name.gsub(/\n/,'').strip,
          metal_level: metal_level.gsub(/\n/,'').strip,
          csr_variation_type: csr_variation_type.gsub(/\n/,'').strip,
          issuer_actuarial_value: (issuer_actuarial_value.gsub(/\n/,'').strip rescue ""),
          av_calculator_output_number: (av_calculator_output_number.gsub(/\n/,'').strip rescue ""),
          medical_and_drug_deductibles_integrated: medical_and_drug_deductibles_integrated.gsub(/\n/,'').strip,
          medical_and_drug_max_out_of_pocket_integrated: medical_and_drug_max_out_of_pocket_integrated.gsub(/\n/,'').strip,
          multiple_provider_tiers: multiple_provider_tiers.gsub(/\n/,'').strip,
          first_tier_utilization: first_tier_utilization.gsub(/\n/,'').strip,
          second_tier_utilization: second_tier_utilization.gsub(/\n/,'').strip,
          default_copay_in_network: default_copay_in_network.present? ? default_copay_in_network.gsub(/\n/,'').strip : "",
          default_copay_out_of_network: default_copay_out_of_network.present? ? default_copay_out_of_network.gsub(/\n/,'').strip : "",
          default_co_insurance_in_network: default_co_insurance_in_network.present? ? default_co_insurance_in_network.gsub(/\n/,'').strip : "",
          default_co_insurance_out_of_network: default_co_insurance_out_of_network.present? ? default_co_insurance_out_of_network.gsub(/\n/,'').strip : ""
        },
        maximum_out_of_pockets_attributes: maximum_out_of_pockets_attributes.map(&:to_hash),
        deductible_attributes: deductible_attributes.to_hash,
        hsa_attributes: hsa_attributes.present? ? hsa_attributes.to_hash : {},
        service_visits_attributes: service_visits_attributes.map(&:to_hash)
      }
      response[:sbc_attributes] = sbc_attributes.to_hash if sbc_attributes
      response
    end
  end
end