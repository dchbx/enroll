# frozen_string_literal: true

#sponsored_benefits/organizations/plan_design_proposals/60e466ce1548433bbf45cf08/plan_selections/new?profile_id=60e4460a297c6a786b63dd0d
class BrokerHealthBenefitsPage
 
  def self.by_carrier_tab
    '.col-xs-4.single-carrier-tab'
  end
    
  def self.by_meta_level_tab
    '.col-xs-4.metal-level-tab'
  end

  def self.bronze_radiotbtn
    'metal_level_for_elected_plan_bronze'
  end

  def self.silver_radiobtn
    '#metal_level_for_elected_plan_silver'
  end

  def self.gold_radiobtn
    'metal_level_for_elected_plan_gold'
  end

  def self.platinum_radiobtn
    'metal_level_for_elected_plan_platinum'
  end

  def self.by_single_plan_tab
    '.col-xs-4.single-plan-tab'
  end

  def self.return_to_quote_management_btn
    '.btn.btn-primary.interaction-click-control-return-to-quote-management'
  end

  def self.employer_employee_contribution
    'forms_plan_design_proposal_profile_benefit_sponsorship_benefit_application_benefit_group_relationship_benefits_attributes_0_premium_pct'
  end

  def self.employer_spouse_contribution
    'forms_plan_design_proposal_profile_benefit_sponsorship_benefit_application_benefit_group_relationship_benefits_attributes_1_premium_pct'
  end

  def self.employer_domestic_partner_contribution
    'forms_plan_design_proposal_profile_benefit_sponsorship_benefit_application_benefit_group_relationship_benefits_attributes_2_premium_pct'
  end

  def self.employer_child_under_26_contribution
    'forms_plan_design_proposal_profile_benefit_sponsorship_benefit_application_benefit_group_relationship_benefits_attributes_3_premium_pct'
  end

  def self.select_dental_benefit_btn
    '#AddDentalToPlanDesignProposal'
  end

  def self.save_quote_btn
    '#submitPlanDesignProposal'
  end

  def self.copy_quote_btn
    '#copyPlanDesignProposal'
  end

  def self.review_quote_btn
    '#reviewPlanDesignProposal'
  end

  def self.publish_quote_btn
    '#publishPlanDesignProposal'
  end

  def self.select_refrence_plan
    'input[name="reference_plan"]'
  end
end    