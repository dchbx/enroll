# frozen_string_literal: true

# insured/families/find_sep?utf8=&authenticity_token&waiver_reason=&is_waiving=&person_id&coverage_household_id=&enrollment_kind=&family_member_id&market_kind=individual&coverage_kind=health
class IvlSpecialEnrollmentPeriod

  def self.covid_link
    '.interaction-click-control-covid-19'
  end

  def self.had_a_baby_link
    '.interaction-click-control-had-a-baby'
  end

  def self.adopted_a_child_link
    '.interaction-click-control-adopted-a-child'
  end

  def self.lost_or_will_lose_health_insurance_link
    '.interaction-click-control-lost-or-will-soon-lose-other-health-insurance'
  end

  def self.married_link
    '.interaction-click-control-married'
  end

  def self.backward_arrow
    'i.fa-angle-left'
  end

  def self.forward_arrow
    'i.fa-angle-right'
  end

  def self.none_apply_checkbox
    '#no_qle_checkbox'
  end

  def self.outside_open_enrollment_close_btn
    '.interaction-click-control-close'
  end

  def self.outside_open_enrollment_back_to_my_account_btn
    '.interaction-click-control-back-to-my-account'
  end

  def self.qle_date
    'qle_date'
  end

  def self.continue_qle_btn
    '#qle_submit'
  end

  def self.select_effective_date_dropdown
    'effective_on_kind'
  end

  def self.effective_date_continue_btn
    'div.text-center input.interaction-click-control-continue'
  end
end