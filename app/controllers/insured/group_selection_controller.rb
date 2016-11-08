class Insured::GroupSelectionController < ApplicationController
  before_action :initialize_common_vars, only: [:create, :terminate_selection]
  # before_action :is_under_open_enrollment, only: [:new]

  def select_market(person, params)
    return params[:market_kind] if params[:market_kind].present?
    if @person.try(:has_active_employee_role?)
      'shop'
    elsif @person.try(:has_active_consumer_role?)
      'individual'
    else
      nil
    end
  end

  def new
    set_bookmark_url
    initialize_common_vars
    @employee_role = @person.active_employee_roles.first if @employee_role.blank? and @person.has_active_employee_role?
    @market_kind = select_market(@person, params)

    if @market_kind == 'individual' || (@person.try(:has_active_employee_role?) && @person.try(:has_active_consumer_role?))
      if params[:hbx_enrollment_id].present?
        session[:pre_hbx_enrollment_id] = params[:hbx_enrollment_id]
        pre_hbx = HbxEnrollment.find(params[:hbx_enrollment_id])
        pre_hbx.update_current(changing: true) if pre_hbx.present?
      end
      hbx = HbxProfile.current_hbx
      bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first
      pkgs = bc_period.benefit_packages
      benefit_package = pkgs.select{|plan|  plan[:title] == "individual_health_benefits_2015"}
      @benefit = benefit_package.first
      @aptc_blocked = @person.primary_family.is_blocked_by_qle_and_assistance?(nil, session["individual_assistance_path"])
    end
    if (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep')
      @disable_market_kind = @market_kind == "shop" ? "individual" : "shop"
    end
    insure_hbx_enrollment_for_shop_qle_flow
    @waivable = @hbx_enrollment.can_complete_shopping? if @hbx_enrollment.present?
    @new_effective_on = HbxEnrollment.calculate_effective_on_from(
      market_kind:@market_kind,
      qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
      family: @family,
      employee_role: @employee_role,
      benefit_group: @employee_role.present? ? @employee_role.benefit_group : nil,
      benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship))
  end

  def create
    keep_existing_plan = params[:commit] == "Keep existing plan"
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'

    return redirect_to purchase_insured_families_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"

    raise "You must select at least one Eligible applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?
    family_member_ids = params.require(:family_member_ids).collect() do |index, family_member_id|
      BSON::ObjectId.from_string(family_member_id)
    end

    hbx_enrollment = build_hbx_enrollment
    if (keep_existing_plan && @hbx_enrollment.present?)
      sep_id = @hbx_enrollment.is_shop? ? @hbx_enrollment.family.earliest_effective_shop_sep.id : @hbx_enrollment.family.earliest_effective_ivl_sep.id
      hbx_enrollment.special_enrollment_period_id = sep_id
      hbx_enrollment.plan = @hbx_enrollment.plan
    end

    hbx_enrollment.hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members.select do |member|
      family_member_ids.include? member.applicant_id
    end
    hbx_enrollment.generate_hbx_signature

    @family.hire_broker_agency(current_user.person.broker_role.try(:id))
    hbx_enrollment.writing_agent_id = current_user.person.try(:broker_role).try(:id)
    hbx_enrollment.original_application_type = session[:original_application_type]
    broker_role = current_user.person.broker_role
    hbx_enrollment.broker_agency_profile_id = broker_role.broker_agency_profile_id if broker_role


    hbx_enrollment.coverage_kind = @coverage_kind

    if hbx_enrollment.save
      hbx_enrollment.inactive_related_hbxs # FIXME: bad name, but might go away
      if keep_existing_plan
        hbx_enrollment.update_coverage_kind_by_plan
        redirect_to purchase_insured_families_path(change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, hbx_enrollment_id: hbx_enrollment.id)
      elsif @change_plan.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, enrollment_kind: @enrollment_kind)
      else
        # FIXME: models should update relationships, not the controller
        hbx_enrollment.benefit_group_assignment.update(hbx_enrollment_id: hbx_enrollment.id) if hbx_enrollment.benefit_group_assignment.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, market_kind: @market_kind, coverage_kind: @coverage_kind, enrollment_kind: @enrollment_kind)
      end
    else
      raise "You must select the primary applicant to enroll in the healthcare plan"
    end
  rescue Exception => error
    flash[:error] = error.message
    logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
    employee_role_id = @employee_role.id if @employee_role
    consumer_role_id = @consumer_role.id if @consumer_role
    return redirect_to new_insured_group_selection_path(person_id: @person.id, employee_role_id: employee_role_id, change_plan: @change_plan, market_kind: @market_kind, consumer_role_id: consumer_role_id, enrollment_kind: @enrollment_kind)
  end

  def terminate_selection
    @hbx_enrollments = @family.enrolled_hbx_enrollments.select{|pol| pol.may_terminate_coverage? } || []
  end

  def terminate_confirm
    @hbx_enrollment = HbxEnrollment.find(params.require(:hbx_enrollment_id))
  end

  def terminate
    term_date = Date.strptime(params.require(:term_date),"%m/%d/%Y")
    hbx_enrollment = HbxEnrollment.find(params.require(:hbx_enrollment_id))

    if hbx_enrollment.may_terminate_coverage?
      hbx_enrollment.termination_submitted_on = TimeKeeper.datetime_of_record
      hbx_enrollment.terminate_benefit(term_date)
      hbx_enrollment.propogate_terminate(term_date)
      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  private

  def build_hbx_enrollment
    case @market_kind
    when 'shop'
      if @hbx_enrollment.present?
        benefit_group = @hbx_enrollment.benefit_group
        benefit_group_assignment = @hbx_enrollment.benefit_group_assignment
        @change_plan = 'change_by_qle' if @hbx_enrollment.is_special_enrollment?
      end
      @employee_role = @person.active_employee_roles.first if @employee_role.blank? and @person.has_active_employee_role?
      @coverage_household.household.new_hbx_enrollment_from(
        employee_role: @employee_role,
        coverage_household: @coverage_household,
        benefit_group: benefit_group,
        benefit_group_assignment: benefit_group_assignment,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'))
    when 'individual'
      @coverage_household.household.new_hbx_enrollment_from(
        consumer_role: @person.consumer_role,
        coverage_household: @coverage_household,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'))
    end
  end


  def initialize_common_vars
    person_id = params.require(:person_id)
    @person = Person.find(person_id)
    @family = @person.primary_family
    @coverage_household = @family.active_household.immediate_family_coverage_household
    @hbx_enrollment = HbxEnrollment.find(params[:hbx_enrollment_id]) if params[:hbx_enrollment_id].present?

    if params[:employee_role_id].present?
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
      @role = @employee_role
    else
      @consumer_role = @person.consumer_role
      @role = @consumer_role
    end

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    @shop_for_plans = params[:shop_for_plans].present? ? params{:shop_for_plans} : ''
  end

  def insure_hbx_enrollment_for_shop_qle_flow
    if @market_kind == 'shop' && (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && @hbx_enrollment.blank?
      @hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
    end
  end

  private

  # def is_under_open_enrollment
  #   if @employee_role.present? && !@employee_role.is_under_open_enrollment?
  #     flash[:alert] = "You can only shop for plans during open enrollment."
  #     redirect_to family_account_path
  #   end
  # end
end
