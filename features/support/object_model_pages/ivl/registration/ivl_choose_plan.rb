# frozen_string_literal: true

#insured/plan_shoppings/5ff897c796a4a17b7bf8930b?coverage_kind=health&enrollment_kind=&market_kind=individual
class IvlChoosePlan

  def self.find_your_doctor_link
    '.interaction-click-control-find-your-doctor'
  end

  def self.estimate_your_cost_link
    'interaction-click-control-estimate-your-cost'
  end

  def self.hmo_checkbox
    'label[for="checkbox-10"]'
  end

  def self.hsa_eligible_dropdown
    'hsa_eligibility'
  end

  def self.plan_name_btn
    '.interaction-click-control-plan-name'
  end

  def self.premium_amount_btn
    '.interaction-click-control-premium-amount'
  end

  def self.deductible_btn
    '.interaction-click-control-deductible'
  end

  def self.carrier_btn
    '.interaction-click-control-carrier'
  end

  def self.apply_btn
    '.interaction-click-control-apply'
  end

  def self.reset_btn
    '#reset-btn'
  end

  def self.select_plan_btn
    '.plan-select'
  end

  def self.see_details_btn
    'div.col-xs-5 a[href^="/products/plans/summary?active_year"]'
  end

  def self.help_me_sign_up_btn
    '.help-me-sign-up'
  end

  def self.continue_btn
    '.interaction-click-control-continue'
  end
end