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

  def set_eligibility_and_effective_dates_to_previous_eligibility_dates(previous_enrollment_id)
    if previous_enrollment_id.present?
      previous_enrollment = HbxEnrollment.find(previous_enrollment_id)
      return if hbx_enrollment.plan.active_year != previous_enrollment.plan.active_year
      previous_enrollment_members = {}
      previous_enrollment.hbx_enrollment_members.each do |hbx_em|
        hbx_id = hbx_em.person.hbx_id
        unless hbx_em.eligibility_date.blank?
          previous_enrollment_members[hbx_id] = hbx_em.eligibility_date
        else
          previous_enrollment_members[hbx_id] = hbx_em.coverage_start_on
        end
      end
    else
      current_year = hbx_enrollment.coverage_year
      current_year_enrollments = hbx_enrollment.household.hbx_enrollments.select{|hbx_enrollment| hbx_enrollment.coverage_year == current_year}
      return if current_year_enrollments.blank?
      current_year_enrollments.sort_by!{|cye| cye.effective_on}
      previous_enrollment_members = {}
      current_year_enrollments.each do |hbx_enrollment|
        next if hbx_enrollment.aasm_state == 'coverage_canceled'
        hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
          hbx_id = hbx_em.person.hbx_id
          unless hbx_em.eligibility_date.blank?
            potential_eligibility_date = hbx_em.eligibility_date
          else
            potential_eligibility_date = hbx_em.coverage_start_on
          end
          if previous_enrollment_members[hbx_id].blank?
            previous_enrollment_members[hbx_id] = potential_eligibility_date
          else
            current_date = previous_enrollment_members[hbx_id]
            if current_date > potential_eligibility_date
              previous_enrollment_members[hbx_id] = potential_eligibility_date
            end
          end
        end
      end
    end
    hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
      hbx_id = hbx_em.person.hbx_id
      unless previous_enrollment_members[hbx_id].blank?
        hbx_em.eligibility_date = previous_enrollment_members[hbx_id]
        hbx_em.coverage_start_on = previous_enrollment_members[hbx_id]
        hbx_em.save!
      end
    end
    hbx_enrollment.save!
  end

  def self.for_enrollment_id_and_plan_id(enrollment_id, plan_id)
    plan = Plan.find(plan_id)
    hbx_enrollment = HbxEnrollment.find(enrollment_id)
    self.new(hbx_enrollment, plan)
  end
end
