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

  # FIXME: Needs to deactivate the parent enrollment, also, we set the sep here? WAT
  def select_plan_and_deactivate_other_enrollments(previous_enrollment_id, market_kind)
    hbx_enrollment.update_current(product_id: plan.id, issuer_profile_id: plan.issuer_profile_id)

    qle = hbx_enrollment.is_special_enrollment?
    if qle
      sep_id = hbx_enrollment.is_shop? ? hbx_enrollment.family.earliest_effective_shop_sep.id
      : hbx_enrollment.family.earliest_effective_ivl_sep.id

      hbx_enrollment.special_enrollment_period_id = sep_id
    end
    hbx_enrollment.aasm_state = 'auto_renewing' if hbx_enrollment.is_active_renewal_purchase?
#    if enrollment_members_verification_status(market_kind)
#      hbx_enrollment.move_to_contingent!
#    else
    hbx_enrollment.select_coverage!(qle: qle)
#    end
    hbx_enrollment.update_existing_shop_coverage
  end

  def enrollment_members_verification_status(market_kind)
    members = hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role)
    if market_kind == "individual"
      return  (members.compact.present? && (members.any?(&:verification_outstanding?) || members.any?(&:verification_period_ended?)))
    else
      return false
    end
  end

  def self.for_enrollment_id_and_plan_id(enrollment_id, plan_id)
    plan = BenefitMarkets::Products::Product.find(plan_id)
    hbx_enrollment = HbxEnrollment.find(enrollment_id)
    self.new(hbx_enrollment, plan)
  end

  def family
    hbx_enrollment.family
  end

  def verify_and_set_member_coverage_start_dates
    if existing_coverage.present? && (existing_coverage.product_id == plan.id)
      set_enrollment_member_coverage_start_dates(hbx_enrollment)
    end
  end

=begin
  def same_plan_enrollment
    return @same_plan_enrollment if defined? @same_plan_enrollment

    @same_plan_enrollment = family.active_household.hbx_enrollments.new(hbx_enrollment.dup.attributes)
    @same_plan_enrollment.hbx_enrollment_members = build_hbx_enrollment_members
    @same_plan_enrollment = set_enrollment_member_coverage_start_dates(@same_plan_enrollment)

    @same_plan_enrollment
  end
=end

  def build_hbx_enrollment_members
    hbx_enrollment.hbx_enrollment_members.collect do |hbx_enrollment_member|
      HbxEnrollmentMember.new({
        applicant_id: hbx_enrollment_member.applicant_id,
        eligibility_date: hbx_enrollment.effective_on,
        coverage_start_on: hbx_enrollment.effective_on,
        is_subscriber: hbx_enrollment_member.is_subscriber
      })
    end
  end

  def existing_coverage
    @hbx_enrollment.parent_enrollment
  end

  def set_enrollment_member_coverage_start_dates(enrollment_obj = hbx_enrollment)

    if existing_coverage.present?
      previous_enrollment_members = existing_coverage.hbx_enrollment_members

      enrollment_obj.hbx_enrollment_members.each do |member|
        matched = previous_enrollment_members.detect{|enrollment_member| enrollment_member.hbx_id == member.hbx_id}

        if matched
          member.coverage_start_on = matched.coverage_start_on || existing_coverage.effective_on
        end
      end
    end

    enrollment_obj
  end

=begin
  def existing_enrollment_for_covered_individuals
    previous_active_coverages.detect{|en|
      (en.hbx_enrollment_members.collect(&:hbx_id) & hbx_enrollment.hbx_enrollment_members.collect(&:hbx_id)).present? && en.id != hbx_enrollment.id
    }
  end

  def previous_active_coverages
    coverage_year_start = hbx_enrollment.effective_on.year

    family.active_household.hbx_enrollments.where({
      :_id.ne => hbx_enrollment.id,
      :kind => hbx_enrollment.kind,
      :coverage_kind => hbx_enrollment.coverage_kind,
      :effective_on.gte => coverage_year_start,
      }).or(
        {:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES},
        {:aasm_state.in => HbxEnrollment::TERMINATED_STATUSES, :terminated_on.gte => hbx_enrollment.effective_on.prev_day}
      ).order("effective_on DESC")
  end
=end
  def family
    @hbx_enrollment.family
  end
end
