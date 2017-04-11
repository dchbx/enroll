class Insured::GroupSelectionController < ApplicationController
  before_action :initialize_common_vars, only: [:create, :terminate_selection]
  # before_action :is_under_open_enrollment, only: [:new]

  def select_market(params)
    return params[:market_kind] if params[:market_kind]
    if @person.try(:has_active_employee_role?)
      "shop"
    elsif @person.try(:has_active_consumer_role?)
      "individual"
    elsif @person.try(:has_active_resident_role?)
      "coverall"
    else
      nil
    end
  end


  def get_correct_effective_on(market_kind, qle, family, employee_role, benefit_group, sponser_ship)
    HbxEnrollment.calculate_effective_on_from(market_kind: market_kind,
                                              qle: qle,
                                              family: family,
                                              employee_role: employee_role,
                                              benefit_group: benefit_group,
                                              benefit_sponsorship: sponser_ship)
  end

  def plan_Status_Type
    @change_plan == "change_by_qle" || @enrollment_kind == "sep"
  end

  def fetch_date(value)
    Date.strptime(value, '%m/%d/%Y')
  end

  def new
    set_bookmark_url
    initialize_common_vars

    @employee_role = @person.active_employee_roles.first if @employee_role.blank? && @person.has_active_employee_role?

    @resident = Person.find(params[:person_id]) if Person.find(params[:person_id]).resident_role?
    is_active = @person.try(:has_active_employee_role?) && @person.try(:has_active_consumer_role?)

    if @market_kind == "individual" || is_active || @resident
      if params[:hbx_enrollment_id]
        session[:pre_hbx_enrollment_id] = params[:hbx_enrollment_id]
        pre_hbx = HbxEnrollment.find(params[:hbx_enrollment_id])
        pre_hbx.update_current(changing: true) if pre_hbx
      end

      sponser_ship = HbxProfile.current_hbx.try(:benefit_sponsorship)
      correct_effective_on = get_correct_effective_on("individual", plan_Status_Type, @family, nil, nil, sponser_ship)
      benefit_Coverage = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods
      benefit_Packages =benefit_Coverage.select{|bcp| bcp.contains?(correct_effective_on)}.first.benefit_packages
      @benefit = benefit_Packages.select{|bp|  bp[:title] == "individual_health_benefits_#{correct_effective_on.year}"}.first
    end

    if plan_Status_Type
      @disable_market_kind = @market_kind == "shop" ? "individual" : "shop"
    end

    if @market_kind == "shop"
      insure_hbx_enrollment_for_shop_qle_flow
      generate_coverage_family_members_for_cobra
    end

    benefit_group = @employee_role.present? ? @employee_role.benefit_group : nil
    @new_effective_on = get_correct_effective_on(@market_kind, plan_Status_Type, @family, @employee_role, benefit_group,sponser_ship)
    # Set @new_effective_on to the date choice selected by user if this is a QLE with date options available.
    @new_effective_on = fetch_date(params[:effective_on_option_selected]) if params[:effective_on_option_selected].present?
  end

  def create
    return redirect_to purchase_insured_families_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"

    raise "You must select at least one Eligible applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?

    keep_existing_plan = params[:commit] == "Keep existing plan"
    family_member_ids = params[:family_member_ids].collect() do |_, family_member_id|
      BSON::ObjectId.from_string(family_member_id)
    end

    hbx_enrollment = build_hbx_enrollment

    if keep_existing_plan && @hbx_enrollment
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

    if @employee_role.present? && @employee_role.is_cobra_status?
      hbx_enrollment.kind = 'employer_sponsored_cobra'
      hbx_enrollment.effective_on = @employee_role.census_employee.coverage_terminated_on.end_of_month + 1.days if @employee_role.census_employee.need_update_hbx_enrollment_effective_on?
      if @employee_role.census_employee.coverage_terminated_on.present? && !@employee_role.census_employee.have_valid_date_for_cobra?
        raise "You may not enroll for cobra after #{Settings.aca.shop_market.cobra_enrollment_period.months} months later of coverage terminated."
      end
    end

    # Set effective_on if this is a case of QLE with date options available.
    hbx_enrollment.effective_on = Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y') if params[:effective_on_option_selected].present?

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
    term_date = fetch_date(params[:term_date])
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
    #see the difference in employee_role new and create
    case @market_kind
      when "shop"
        @employee_role = @person.active_employee_roles.first if @employee_role.blank? and @person.has_active_employee_role?
        if @hbx_enrollment.present?
          @change_plan = "change_by_qle" if @hbx_enrollment.is_special_enrollment?
          if @employee_role == @hbx_enrollment.employee_role
            benefit_group = @hbx_enrollment.benefit_group
            benefit_group_assignment = @hbx_enrollment.benefit_group_assignment
          else
            benefit_group = @employee_role.benefit_group
            benefit_group_assignment = @employee_role.census_employee.active_benefit_group_assignment
          end
        end
        @coverage_household.household.new_hbx_enrollment_from(employee_role: @employee_role,
                                                              resident_role: @person.resident_role,
                                                              coverage_household: @coverage_household,
                                                              benefit_group: benefit_group,
                                                              benefit_group_assignment: benefit_group_assignment,
                                                              qle: plan_Status_Type)
      when "individual" || "coverall"
        @coverage_household.household.new_hbx_enrollment_from(consumer_role: @person.consumer_role,
                                                              resident_role: @person.resident_role,
                                                              coverage_household: @coverage_household,
                                                              qle: plan_Status_Type)
    end
  end


  def initialize_common_vars
    #check market kind for new and create
    @person = Person.find(params[:person_id])
    @family = @person.primary_family
    @coverage_household = @family.active_household.immediate_family_coverage_household
    @market_kind = select_market(params)
    @hbx_enrollment = HbxEnrollment.find(params[:hbx_enrollment_id]) if params[:hbx_enrollment_id]

    if params[:employee_role_id]
      emp_role_id = params[:employee_role_id]
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
      @role = @employee_role
    elsif params[:resident_role_id]
      @resident_role = @person.resident_role
      @role = @resident_role
    else
      @consumer_role = @person.consumer_role
      @role = @consumer_role
    end

    @change_plan = params[:change_plan] ? params[:change_plan] : ""
    @coverage_kind = params[:coverage_kind] ? params[:coverage_kind] : "health"
    @enrollment_kind = params[:enrollment_kind] ? params[:enrollment_kind] : ""
    @shop_for_plans = params[:shop_for_plans] ? params{:shop_for_plans} : ""
  end


  def retrieve_desc
    @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc
  end

  def insure_hbx_enrollment_for_shop_qle_flow
    if  plan_Status_Type && @hbx_enrollment.blank?
      @hbx_enrollment = retrieve_desc.detect { |hbx| hbx.may_terminate_coverage? }
    end
  end

  def generate_coverage_family_members_for_cobra
    if  !plan_Status_Type && @employee_role.present? && @employee_role.is_cobra_status?
      hbx_enrollment = retrieve_desc.detect { |hbx| hbx.may_terminate_coverage? }
      @coverage_family_members_for_cobra = hbx_enrollment.hbx_enrollment_members.map(&:family_member) if hbx_enrollment
    end
  end
end