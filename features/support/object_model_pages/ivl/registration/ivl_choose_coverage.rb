# frozen_string_literal: true

#insured/group_selections/new?change_plan=&consumer_role_id&person_id
class IvlChooseCoverage

  def self.choose_coverage_for_your_household_text
    'Choose Coverage for your Household'
  end
  
  def self.primary_checkbox
    '#family_member_ids_0'
  end

  def self.dependent_1_checkbox
    '#family_member_ids_1'
  end

  def self.individual_benefits_radiobtn
    'label[for="market_kind_individual"] span'
  end

  def self.health_radiobtn
    'label[for="coverage_kind_health"] span'
  end

  def self.dental_radiobtn
    'label[for="coverage_kind_dental"] span'
  end

  def self.shop_for_new_plan_btn
    'input[class="btn btn-primary  btn-lg no-op  interaction-click-control-shop-for-new-plan"]'
  end

  def self.back_to_my_acct_btn
    '.interaction-click-control-back-to-my-account'
  end

  def self.continue_btn
    '.interaction-click-control-continue'
  end
end