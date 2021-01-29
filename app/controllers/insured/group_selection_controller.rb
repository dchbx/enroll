class Insured::GroupSelectionController < ApplicationController
  include Insured::GroupSelectionHelper

  before_action :permit_params, only: [:create]
  before_action :initialize_common_vars, only: [:new, :create, :terminate_selection]
  # before_action :set_vars_for_market, only: [:new]
  # before_action :is_under_open_enrollment, only: [:new]

  def new
    set_bookmark_url
    set_admin_bookmark_url
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
        pre_hbx.update_attributes!(changing: true) if pre_hbx.present?
      end

      @benefit = @adapter.ivl_benefit
    end
    @qle = @adapter.is_qle?

    insure_hbx_enrollment_for_shop_qle_flow

    set_change_plan

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

    @waivable = @adapter.can_waive?(@hbx_enrollment, params)
    @fm_hash = {}
    # Only check eligibility for *active* family members because
    # family members "deleted" with family#remove_family_member
    # are set to is_active = false
    @active_family_members = @family.family_members.active
    @active_family_members.each do |family_member|
      family_member_eligibility_check(family_member)
    end
    if @fm_hash.present? && @fm_hash.values.flatten.detect{|err| err.to_s.match(/incarcerated_not_answered/)}
      redirect_to manage_family_insured_families_path(tab: 'family')
      flash[:error] = "A family member has incarceration status unanswered, please answer the question by clicking on edit icon before shopping."
    end
  end

  def create
    keep_existing_plan = @adapter.keep_existing_plan?(params)
    @market_kind = @adapter.create_action_market_kind(params)
    return redirect_to purchase_insured_families_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"
    if (@market_kind == 'shop' || @market_kind == 'fehb') && @employee_role.census_employee.present?
      new_hire_enrollment_period = @employee_role.census_employee.new_hire_enrollment_period
      if new_hire_enrollment_period.begin > TimeKeeper.date_of_record
        raise "You're not yet eligible under your employer-sponsored benefits. Please return on #{new_hire_enrollment_period.begin.strftime("%m/%d/%Y")} to enroll for coverage."
      end
    end

    unless @adapter.is_waiving?(params)
      raise "You must select at least one Eligible applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?
      family_member_ids = params.require(:family_member_ids).to_h.collect do |_index, family_member_id|
        BSON::ObjectId.from_string(family_member_id)
      end
    end

    hbx_enrollment = build_hbx_enrollment(family_member_ids)
    if @market_kind == 'shop' || @market_kind == 'fehb'

      raise "Unable to find employer-sponsored benefits for enrollment year #{hbx_enrollment.effective_on.year}" unless hbx_enrollment.sponsored_benefit_package.shoppable?

      census_effective_on = @employee_role.census_employee.coverage_effective_on(hbx_enrollment.sponsored_benefit_package)
      if census_effective_on > hbx_enrollment.effective_on
        raise 'You are attempting to purchase coverage through Qualifying Life Event prior to your eligibility date.'\
              ' Please contact your Employer for assistance. You are eligible for employer benefits from ' + census_effective_on.strftime('%m/%d/%Y')
      end

      if @adapter.is_waiving?(params)
        raise "Waive Coverage Failed" unless hbx_enrollment.save

        @adapter.assign_enrollment_to_benefit_package_assignment(@employee_role, hbx_enrollment)
        redirect_to waive_insured_plan_shopping_path(:id => hbx_enrollment.id, :waiver_reason => hbx_enrollment.waiver_reason)
        return
      end
    end

    if @adapter.keep_existing_plan?(params) && @adapter.previous_hbx_enrollment.present?
      sep = @hbx_enrollment.earlier_effective_sep_by_market_kind

      if sep.present?
        hbx_enrollment.special_enrollment_period_id = sep.id
      end

      hbx_enrollment.product = @hbx_enrollment.product
    end

    select_enrollment_members(hbx_enrollment, family_member_ids) if @market_kind == 'individual' || @market_kind == 'coverall'

    hbx_enrollment.generate_hbx_signature
    @adapter.family.hire_broker_agency(current_user.person.broker_role.try(:id))
    hbx_enrollment.writing_agent_id = current_user.person.try(:broker_role).try(:id)
    hbx_enrollment.original_application_type = session[:original_application_type]
    broker_role = current_user.person.broker_role
    hbx_enrollment.broker_agency_profile_id = broker_role.broker_agency_profile_id if broker_role

    hbx_enrollment.coverage_kind = @coverage_kind
    hbx_enrollment.validate_for_cobra_eligiblity(@employee_role, current_user)

    hbx_enrollment.kind = @market_kind if (hbx_enrollment.kind != @market_kind) && @market_kind != 'shop' && @market_kind != 'fehb'

    if hbx_enrollment.save
      if @market_kind == 'individual' || @market_kind == 'coverall'
        hbx_enrollment.inactive_related_hbxs # FIXME: bad name, but might go away
      elsif @market_kind == 'shop' || @market_kind == 'fehb'
        @adapter.assign_enrollment_to_benefit_package_assignment(@employee_role, hbx_enrollment)
      end

      if (@market_kind == 'individual' || @market_kind == 'coverall') && keep_existing_plan
        hbx_enrollment.update_coverage_kind_by_plan
        redirect_to purchase_insured_families_path(change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, hbx_enrollment_id: hbx_enrollment.id)
      elsif (@market_kind == 'shop' || @market_kind == 'fehb') && keep_existing_plan && @adapter.previous_hbx_enrollment.present?
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
    @termination_date_options = @family.options_for_termination_dates(@hbx_enrollments)
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
      redirect_back(fallback_location: :back)
    end
  end

  def edit_plan
    @self_term_or_cancel_form = ::Insured::Forms::SelfTermOrCancelForm.for_view({enrollment_id: params.require(:hbx_enrollment_id), family_id: params.require(:family_id)})
  end

  def term_or_cancel
    @self_term_or_cancel_form = ::Insured::Forms::SelfTermOrCancelForm.for_post({enrollment_id: params.require(:hbx_enrollment_id), term_date: params[:term_date], term_or_cancel: params[:term_or_cancel]})

    if @self_term_or_cancel_form.errors.present?
      flash[:error] = @self_term_or_cancel_form.errors.values.flatten.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}
      redirect_to edit_plan_insured_group_selections_path(hbx_enrollment_id: params[:hbx_enrollment_id], family_id: params[:family_id])
    else
      redirect_to family_account_path
    end
  end

  def edit_aptc
    attrs = {enrollment_id: params.require(:hbx_enrollment_id), elected_aptc_pct: params[:applied_pct_1], aptc_applied_total: params[:aptc_applied_total].delete_prefix('$')}
    begin
      message = ::Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
      flash[:notice] = message
    rescue StandardError => e
      flash[:error] = "Unable to update tax credits for enrollment"
    end

    redirect_to family_account_path
  end

  private

  def family_member_eligibility_check(family_member)
    return unless (@adapter.can_shop_individual?(@person) || @adapter.can_shop_resident?(@person))

    role = if family_member.person.is_consumer_role_active?
             family_member.person.consumer_role
           elsif family_member.person.is_resident_role_active?
             family_member.person.resident_role
           end

    rule = InsuredEligibleForBenefitRule.new(role, @benefit, {family: @family, coverage_kind: @coverage_kind, new_effective_on: @new_effective_on, market_kind: get_ivl_market_kind(@person)})

    is_ivl_coverage, errors = rule.satisfied?
    person = family_member.person
    incarcerated = person.is_consumer_role_active? && family_member.is_applying_coverage && person.is_incarcerated.nil? ? "incarcerated_not_answered" : family_member.person.is_incarcerated
    @fm_hash[family_member.id] = [is_ivl_coverage, rule, errors, incarcerated]
  end

  def permit_params
    params.permit!
  end

  def permitted_group_selection_paramss
    params.permit(
      :change_plan, :consumer_role_id, :market_kind, :qle_id,
      :hbx_enrollment_id, :coverage_kind, :enrollment_kind,
      :employee_role_id, :resident_role_id, :person_id,
      :market_kind, :shop_for_plans,
      :controller, :action, :commit,
      :effective_on_option_selected,
      :is_waiving, :waiver_reason,
      family_member_ids: {}
    )
  end

  def set_change_plan
    @adapter.if_family_has_active_shop_sep do
      @change_plan = 'change_by_qle'
    end
  end

  def select_enrollment_members(hbx_enrollment, family_member_ids)
    hbx_enrollment.hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members.select do |member|
      family_member_ids.include? member.applicant_id
    end
  end

  def build_hbx_enrollment(family_member_ids)

    @adapter.if_previous_enrollment_was_special_enrollment do
      @change_plan = 'change_by_qle'
    end

    @adapter.if_family_has_active_sep do
      @change_plan = 'change_by_qle'
    end

    case @market_kind
    when 'shop', 'fehb'
      @adapter.if_employee_role_unset_but_can_be_derived(@employee_role) do |e_role|
        @employee_role = e_role
      end

      set_change_plan

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
    if @hbx_enrollment.present? && @change_plan == 'change_plan'
      @mc_market_kind = if @hbx_enrollment.employer_profile.is_a?(BenefitSponsors::Organizations::FehbEmployerProfile)
                          'fehb'
                        elsif @hbx_enrollment.is_shop?
                          'shop'
                        elsif @hbx_enrollment.kind == 'coverall'
                          'coverall'
                        else
                          'individual'
                        end

      @mc_coverage_kind = @hbx_enrollment.coverage_kind
    end

    @adapter.if_consumer_role do |c_role|
      @consumer_role = c_role
      @role = c_role
    end
  end

  def get_values_to_generate_resident_role(person)
    options = {}
    options[:is_applicant] = person.consumer_role.is_applicant
    options[:bookmark_url] = person.consumer_role.bookmark_url
    options[:is_state_resident] = person.consumer_role.is_state_resident
    options[:residency_determined_at] = person.consumer_role.residency_determined_at
    options[:contact_method] = person.consumer_role.contact_method
    options[:language_preference] = person.consumer_role.language_preference
    options
  end
end
