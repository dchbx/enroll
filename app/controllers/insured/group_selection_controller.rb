class Insured::GroupSelectionController < ApplicationController
  include Insured::GroupSelectionHelper

  before_action :initialize_common_vars, only: [:new, :create, :terminate_selection]
  # before_action :set_vars_for_market, only: [:new]
  # before_action :is_under_open_enrollment, only: [:new]

  def new
    set_bookmark_url
    @adapter.disable_market_kinds(params) do |disabled_market_kind|
      @disable_market_kind = disabled_market_kind
    end

    @adapter.set_mc_variables do |market_kind, coverage_kind|
      @mc_market_kind = market_kind
      @mc_coverage_kind = coverage_kind
    end
    @adapter.if_employee_role_unset_but_can_be_derived(@employee_role) do |derived_employee_role|
      @employee_role = derived_employee_role
    end
    @market_kind = @adapter.select_market(params)
    @resident = @adapter.possible_resident_person
    if @adapter.can_ivl_shop?(params)
      if @adapter.if_changing_ivl?(params)
        session[:pre_hbx_enrollment_id] = params[:hbx_enrollment_id]
        pre_hbx = @adapter.previous_hbx_enrollment
        pre_hbx.update_current(changing: true) if pre_hbx.present?
      end

      @benefit = @adapter.ivl_benefit
    end
    @qle = @adapter.is_qle?

    # Benefit group is what we will need to change
    @benefit_group = @adapter.select_benefit_group(params)
    @new_effective_on = @adapter.calculate_new_effective_on(params)

    @adapter.if_should_generate_coverage_family_members_for_cobra(params) do |cobra_members|
      @coverage_family_members_for_cobra = cobra_members
    end
    # Set @new_effective_on to the date choice selected by user if this is a QLE with date options available.
    @adapter.if_qle_with_date_option_selected(params) do |new_effective_date|
      @new_effective_on = new_effective_date
    end

    @adapter.if_change_plan_selected(params) do |new_effective_date|
      @new_effective_on = new_effective_date
    end

    @adapter.if_hbx_enrollment_unset_and_sep_or_qle_change_and_can_derive_previous_shop_enrollment(params, @hbx_enrollment, @new_effective_on) do |enrollment|
      @hbx_enrollment = enrollment
    end
    @waivable = @adapter.can_waive?(@hbx_enrollment, params)
  end

  def create
    @market_kind = @adapter.create_action_market_kind(params)
    return redirect_to purchase_insured_families_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"

    if @employee_role.census_employee.present?
      new_hire_enrollment_period = @employee_role.census_employee.new_hire_enrollment_period
      if new_hire_enrollment_period.begin > TimeKeeper.date_of_record
        raise "You're not yet eligible under your employer-sponsored benefits. Please return on #{new_hire_enrollment_period.begin.strftime("%m/%d/%Y")} to enroll for coverage."
      end
    end

    unless @adapter.is_waiving?(params)
      raise "You must select at least one Eligible applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?
      family_member_ids = params.require(:family_member_ids).collect() do |index, family_member_id|
        BSON::ObjectId.from_string(family_member_id)
      end
    end

    hbx_enrollment = build_hbx_enrollment(family_member_ids)
    if @adapter.is_waiving?(params)
      if hbx_enrollment.save
        @adapter.assign_enrollment_to_benefit_package_assignment(@employee_role, hbx_enrollment)
        redirect_to waive_insured_plan_shopping_path(:id => hbx_enrollment.id, :waiver_reason => hbx_enrollment.waiver_reason)
        return
      else
        raise "Waive Coverage Failed"
      end
    end

    if (@adapter.keep_existing_plan?(params) && @adapter.previous_hbx_enrollment.present?)
      sep = @hbx_enrollment.is_shop? ? @hbx_enrollment.family.earliest_effective_shop_sep : @hbx_enrollment.family.earliest_effective_ivl_sep

      if sep.present?
        hbx_enrollment.special_enrollment_period_id = sep.id
      end
    end

    hbx_enrollment.generate_hbx_signature

    @adapter.family.hire_broker_agency(current_user.person.broker_role.try(:id))
    hbx_enrollment.writing_agent_id = current_user.person.try(:broker_role).try(:id)
    hbx_enrollment.original_application_type = session[:original_application_type]
    broker_role = current_user.person.broker_role
    hbx_enrollment.broker_agency_profile_id = broker_role.broker_agency_profile_id if broker_role

    hbx_enrollment.validate_for_cobra_eligiblity(@employee_role)

    if hbx_enrollment.save
      @adapter.assign_enrollment_to_benefit_package_assignment(@employee_role, hbx_enrollment)
      if @adapter.keep_existing_plan?(params) && @adapter.previous_hbx_enrollment.present?
        redirect_to thankyou_insured_plan_shopping_path(change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @adapter.coverage_kind, id: hbx_enrollment.id, plan_id: @adapter.previous_hbx_enrollment.product_id)
      elsif @change_plan.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @adapter.coverage_kind, enrollment_kind: @adapter.enrollment_kind)
      else
        # FIXME: models should update relationships, not the controller
        hbx_enrollment.benefit_group_assignment.update(hbx_enrollment_id: hbx_enrollment.id) if hbx_enrollment.benefit_group_assignment.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, market_kind: @market_kind, coverage_kind: @adapter.coverage_kind, enrollment_kind: @adapter.enrollment_kind)
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
    if hbx_enrollment.may_terminate_coverage? && term_date >= TimeKeeper.date_of_record
      hbx_enrollment.termination_submitted_on = TimeKeeper.datetime_of_record
      hbx_enrollment.terminate_benefit(term_date)
      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  private

  def build_hbx_enrollment(family_member_ids)
    case @market_kind
    when 'shop'
      @adapter.if_employee_role_unset_but_can_be_derived(@employee_role) do |e_role|
        @employee_role = e_role
      end
      @adapter.if_previous_enrollment_was_special_enrollment do
        @change_plan = 'change_by_qle'
      end
      benefit_group = nil
      benefit_group_assignment = nil

      if @adapter.is_waiving?(params)
        if @adapter.previous_hbx_enrollment.present?
          @adapter.build_change_shop_waiver_enrollment(@employee_role, @change_plan, params)
        else
          @adapter.build_new_shop_waiver_enrollment(@employee_role)
        end
      elsif @adapter.previous_hbx_enrollment.present?
        @adapter.build_shop_change_enrollment(@employee_role, @change_plan, family_member_ids)
      else
        @adapter.build_new_shop_enrollment(@employee_role, family_member_ids)
      end
    when 'individual'
      @adapter.coverage_household.household.new_hbx_enrollment_from(
        consumer_role: @adapter.person.consumer_role,
        resident_role: @adapter.person.resident_role,
        coverage_household: @adapter.coverage_household,
        qle: @adapter.is_qle?,
        opt_effective_on: @adapter.optional_effective_on)
    when 'coverall'
      @adapter.coverage_household.household.new_hbx_enrollment_from(
        consumer_role: @person.consumer_role,
        resident_role: @person.resident_role,
        coverage_household: @adapter.coverage_household,
        qle: @adapter.is_qle?,
        opt_effective_on: @adapter.optional_effective_on)
    end
  end


  def initialize_common_vars
    @adapter = GroupSelectionPrevaricationAdapter.initialize_for_common_vars(params)
    @person = @adapter.person
    @family = @adapter.family
    @coverage_household = @adapter.coverage_household
    @hbx_enrollment = @adapter.previous_hbx_enrollment
    @change_plan = @adapter.change_plan
    @coverage_kind = @adapter.coverage_kind
    @enrollment_kind = @adapter.enrollment_kind
    @shop_for_plans = @adapter.shop_for_plans
    @optional_effective_on = @adapter.optional_effective_on

    @adapter.if_employee_role do |emp_role|
      @employee_role = emp_role
      @role = emp_role
    end

    @adapter.if_resident_role do |res_role|
      @resident_role = res_role
      @role = res_role
    end

    @adapter.if_consumer_role do |c_role|
      @consumer_role = c_role
      @role = c_role
    end
  end
end
