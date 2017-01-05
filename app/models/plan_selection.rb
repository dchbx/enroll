class PlanSelection
  attr_reader :plan, :hbx_enrollment

  def initialize(enrollment, pl)
    @hbx_enrollment = enrollment
    @plan = pl
  end

  def employee_is_shopping_before_hire?
    hbx_enrollment.employee_role.present? && hbx_enrollment.employee_role.hired_on > TimeKeeper.date_of_record
  end

  def may_select_coverage?
    hbx_enrollment.may_select_coverage?
  end

  def can_apply_aptc?(shopping_tax_household, elected_aptc)
    return false if hbx_enrollment.is_shop?
    shopping_tax_household.present? && elected_aptc > 0 && plan.can_use_aptc?
  end

  def apply_aptc_if_needed(shopping_tax_household, elected_aptc, max_aptc)
    if can_apply_aptc?(shopping_tax_household, elected_aptc)
      decorated_plan = UnassistedPlanCostDecorator.new(plan, hbx_enrollment, elected_aptc, shopping_tax_household)
      hbx_enrollment.update_hbx_enrollment_members_premium(decorated_plan)
      hbx_enrollment.update_current(applied_aptc_amount: decorated_plan.total_aptc_amount, elected_aptc_pct: elected_aptc/max_aptc)
    end
  end

  def select_plan_and_deactivate_other_enrollments(previous_enrollment_id)
    hbx_enrollment.update_current(plan_id: plan.id)
    hbx_enrollment.inactive_related_hbxs
    hbx_enrollment.inactive_pre_hbx(previous_enrollment_id)
    if hbx_enrollment.is_special_enrollment?
      sep_id = hbx_enrollment.is_shop? ? hbx_enrollment.family.earliest_effective_shop_sep.id : hbx_enrollment.family.earliest_effective_ivl_sep.id
      hbx_enrollment.special_enrollment_period_id = sep_id
    end
    hbx_enrollment.aasm_state = 'auto_renewing' if hbx_enrollment.is_active_renewal_purchase?
    hbx_enrollment.select_coverage!
  end

  def self.for_enrollment_id_and_plan_id(enrollment_id, plan_id)
    plan = Plan.find(plan_id)
    hbx_enrollment = HbxEnrollment.find(enrollment_id)
    self.new(hbx_enrollment, plan)
  end
end
