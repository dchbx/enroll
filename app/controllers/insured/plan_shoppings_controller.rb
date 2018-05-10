class Insured::PlanShoppingsController < ApplicationController
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include Acapi::Notifiers
  extend Acapi::Notifiers
  include Aptc
  include ApplicationHelper
  before_action :set_current_person, :only => [:receipt, :thankyou, :waive, :show, :plans, :checkout, :terminate]
  before_action :set_kind_for_market_and_coverage, only: [:thankyou, :show, :plans, :checkout, :receipt]

  def checkout
    plan_selection = PlanSelection.for_enrollment_id_and_plan_id(params.require(:id), params.require(:plan_id))

    if plan_selection.employee_is_shopping_before_hire?
      session.delete(:pre_hbx_enrollment_id)
      flash[:error] = "You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance"
      redirect_to family_account_path
      return
    end

    qle = (plan_selection.hbx_enrollment.enrollment_kind == "special_enrollment")

    if !plan_selection.hbx_enrollment.can_select_coverage?(qle: qle)
      if plan_selection.hbx_enrollment.errors.present?
        flash[:error] = plan_selection.hbx_enrollment.errors.full_messages
      end
      redirect_to :back
      return
    end

    get_aptc_info_from_session(plan_selection.hbx_enrollment)
    plan_selection.apply_aptc_if_needed(@shopping_tax_household, @elected_aptc, @max_aptc)
    previous_enrollment_id = session[:pre_hbx_enrollment_id]

    plan_selection.verify_and_set_member_coverage_start_dates
    plan_selection.select_plan_and_deactivate_other_enrollments(previous_enrollment_id,params[:market_kind])

    session.delete(:pre_hbx_enrollment_id)
    redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan], enrollment_kind: params[:enrollment_kind])
  end

  def receipt
    @enrollment = HbxEnrollment.find(params.require(:id))
    plan = @enrollment.plan

    if @enrollment.is_shop?
      @employer_profile = @enrollment.employer_profile
    else
      @shopping_tax_household = get_shopping_tax_household_from_person(@person, @enrollment.effective_on.year)
      applied_aptc = @enrollment.applied_aptc_amount if @enrollment.applied_aptc_amount > 0
      @market_kind = "individual"
    end

    @plan = @enrollment.build_plan_premium(qhp_plan: plan, apply_aptc: applied_aptc.present?, elected_aptc: applied_aptc, tax_household: @shopping_tax_household)

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    employee_mid_year_plan_change(@person, @change_plan)
    # @enrollment.ee_plan_selection_confirmation_sep_new_hire #mirror notice
    # @enrollment.mid_year_plan_change_notice #mirror notice

    # send accepted SEP QLE event notice to enrolled employee
    if @market_kind == "shop" && @enrollment.employee_role_id.present? && @change_plan == "change_by_qle"
       emp_role_id = @enrollment.employee_role_id.to_s
       @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id }
       sep_qle_request_accept_notice_ee(@employee_role.census_employee.id.to_s, @enrollment)
    end

    send_receipt_emails if @person.emails.first
  end

  def thankyou
    set_elected_aptc_by_params(params[:elected_aptc]) if params[:elected_aptc].present?
    set_consumer_bookmark_url(family_account_path)
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))
    @enrollment.set_special_enrollment_period

    if @enrollment.is_shop?
      @employer_profile = @enrollment.employer_profile
    else
      get_aptc_info_from_session(@enrollment)
    end

    @enrollment.reset_dates_on_previously_covered_members(@plan)
    @plan = @enrollment.build_plan_premium(qhp_plan: @plan, apply_aptc: can_apply_aptc?(@plan), elected_aptc: @elected_aptc, tax_household: @shopping_tax_household)
    @family = @person.primary_family

    #FIXME need to implement can_complete_shopping? for individual
    @enrollable = @market_kind == 'individual' ? true : @enrollment.can_complete_shopping?(qle: @enrollment.is_special_enrollment?)
    @waivable = @enrollment.can_complete_shopping?
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    flash.now[:error] = qualify_qle_notice unless @enrollment.can_select_coverage?(qle: @enrollment.is_special_enrollment?)

    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def waive
    person = @person
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    waiver_reason = params[:waiver_reason]

    # Create a new hbx_enrollment for the waived enrollment.
    unless hbx_enrollment.shopping?
      employee_role = @person.employee_roles.active.last if employee_role.blank? and @person.has_active_employee_role?
      coverage_household = @person.primary_family.active_household.immediate_family_coverage_household
      waived_enrollment =  coverage_household.household.new_hbx_enrollment_from(employee_role: employee_role, coverage_household: coverage_household, benefit_group: nil, benefit_group_assignment: nil, qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'))
      waived_enrollment.coverage_kind= hbx_enrollment.coverage_kind
      waived_enrollment.kind = 'employer_sponsored_cobra' if employee_role.present? && employee_role.is_cobra_status?
      waived_enrollment.generate_hbx_signature

      if waived_enrollment.save!
        hbx_enrollment = waived_enrollment
        hbx_enrollment.household.reload # Make sure we reload the household to reflect the newly created HbxEnrollment
      end
    end

    if hbx_enrollment.may_waive_coverage? and waiver_reason.present? and hbx_enrollment.valid?
      hbx_enrollment.waive_coverage_by_benefit_group_assignment(waiver_reason)
      redirect_to print_waiver_insured_plan_shopping_path(hbx_enrollment), notice: "Waive Coverage Successful"

    else
      redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id), alert: "Waive Coverage Failed"
    end
  rescue => e
    log(e.message, :severity=>'error')
    redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id), alert: "Waive Coverage Failed"
  end

  def print_waiver
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
  end

    def employee_mid_year_plan_change(person,change_plan)
     begin
      ce = person.active_employee_roles.first.census_employee
      if change_plan.present? or ce.new_hire_enrollment_period.present?
        trigger_notice_observer(ce.employer_profile, @enrollment, 'employee_mid_year_plan_change_notice_to_employer')
      end
     rescue Exception => e
       log("#{e.message}; person_id: #{person.id}")
     end
    end

  def sep_qle_request_accept_notice_ee(employee_id, enrollment)
    sep = enrollment.special_enrollment_period
    options = { :sep_qle_end_on => sep.end_on.to_s, :sep_qle_title => sep.title, :sep_qle_on => sep.qle_on.to_s }
    begin
      ShopNoticesNotifierJob.perform_later(employee_id, "notify_employee_of_special_enrollment_period", :sep => options)
    rescue Exception => e
      logger.debug("Exception raised in %s" % e.backtrace)
      raise "Unable to trigger sep_qle_request_accept_notice_ee"
    end
  end

  def terminate
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    if hbx_enrollment.may_schedule_coverage_termination?
      hbx_enrollment.termination_submitted_on = TimeKeeper.datetime_of_record
      hbx_enrollment.terminate_reason = params[:terminate_reason] if params[:terminate_reason].present?
      hbx_enrollment.schedule_coverage_termination!(@person.primary_family.terminate_date_for_shop_by_enrollment(hbx_enrollment))
      hbx_enrollment.update_renewal_coverage
      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  def show
    set_consumer_bookmark_url(family_account_path) if params[:market_kind] == 'individual'
    set_employee_bookmark_url(family_account_path) if params[:market_kind] == 'shop'
    set_resident_bookmark_url(family_account_path) if params[:market_kind] == 'coverall'
    hbx_enrollment_id = params.require(:id)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    set_plans_by(hbx_enrollment_id: hbx_enrollment_id)
    shopping_tax_household = get_shopping_tax_household_from_person(@person, @hbx_enrollment.effective_on.year)
    if shopping_tax_household.present? && @hbx_enrollment.coverage_kind == "health" && @hbx_enrollment.kind == 'individual'
      @tax_household = shopping_tax_household
      @max_aptc = @tax_household.total_aptc_available_amount_for_enrollment(@hbx_enrollment)
      session[:max_aptc] = @max_aptc
      @elected_aptc = session[:elected_aptc] = @max_aptc * 0.85
    else
      session[:max_aptc] = 0
      session[:elected_aptc] = 0
    end

    if params[:market_kind] == 'shop' && plan_match_dc
      is_congress_employee = @hbx_enrollment.benefit_group.is_congress
      @dc_checkbook_url = is_congress_employee  ? Settings.checkbook_services.congress_url : ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment).generate_url
    end
    @carriers = @carrier_names_map.values
    @waivable = @hbx_enrollment.try(:can_complete_shopping?)
    @max_total_employee_cost = thousand_ceil(@plans.map(&:total_employee_cost).map(&:to_f).max)
    @max_deductible = thousand_ceil(@plans.map(&:deductible).map {|d| d.is_a?(String) ? d.gsub(/[$,]/, '').to_i : 0}.max)
  end

  def set_elected_aptc
    session[:elected_aptc] = params[:elected_aptc].to_f
    render json: 'ok'
  end

  def plans
    set_consumer_bookmark_url(family_account_path)
    set_plans_by(hbx_enrollment_id: params.require(:id))
    if @person.primary_family.active_household.latest_active_tax_household.present?
      if is_eligibility_determined_and_not_csr_100?(@person)
        sort_for_csr(@plans)
      else
        sort_by_standard_plans(@plans)
        @plans = @plans.partition{ |a| @enrolled_hbx_enrollment_plan_ids.include?(a[:id]) }.flatten
      end
    else
      sort_by_standard_plans(@plans)
      @plans = @plans.partition{ |a| @enrolled_hbx_enrollment_plan_ids.include?(a[:id]) }.flatten
    end
    @plan_hsa_status = Products::Qhp.plan_hsa_status_map(@plans)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
  end

  private

  def sort_by_standard_plans(plans)
    standard_plans, other_plans = plans.partition{|p| p.is_standard_plan? == true}
    standard_plans = standard_plans.sort_by(&:total_employee_cost).sort{|a,b| b.csr_variant_id <=> a.csr_variant_id}
    other_plans = other_plans.sort_by(&:total_employee_cost).sort{|a,b| b.csr_variant_id <=> a.csr_variant_id}
    @plans = standard_plans + other_plans
  end

  def sort_for_csr(plans)
    silver_plans, non_silver_plans = plans.partition{|a| a.metal_level == "silver"}
    standard_plans, non_standard_plans = silver_plans.partition{|a| a.is_standard_plan == true}
    @plans = standard_plans + non_standard_plans + non_silver_plans
  end

  def is_eligibility_determined_and_not_csr_100?(person)
    csr_eligibility_kind = person.primary_family.active_household.latest_active_tax_household.current_csr_eligibility_kind
    (EligibilityDetermination::CSR_KINDS.include? "#{csr_eligibility_kind}") && ("#{csr_eligibility_kind}" != "csr_100")
  end

  def send_receipt_emails
    UserMailer.generic_consumer_welcome(@person.first_name, @person.hbx_id, @person.emails.first.address).deliver_now
    body = render_to_string 'user_mailer/secure_purchase_confirmation.html.erb', layout: false
    from_provider = HbxProfile.current_hbx
    message_params = {
      sender_id: from_provider.try(:id),
      parent_message_id: @person.id,
      from: from_provider.try(:legal_name),
      to: @person.full_name,
      body: body,
      subject: 'Your Secure Enrollment Confirmation'
    }
    create_secure_message(message_params, @person, :inbox)
  end

  def set_plans_by(hbx_enrollment_id:)
    Caches::MongoidCache.allocate(CarrierProfile)
    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    @enrolled_hbx_enrollment_plan_ids = @hbx_enrollment.family.currently_enrolled_plans(@hbx_enrollment)

    if @hbx_enrollment.blank?
      @plans = []
    else
      if @hbx_enrollment.is_shop?
        @benefit_group = @hbx_enrollment.benefit_group
        @plans = @benefit_group.decorated_elected_plans(@hbx_enrollment, @coverage_kind)
      elsif @hbx_enrollment.is_coverall?
        @plans = @hbx_enrollment.decorated_elected_plans(@coverage_kind, @market_kind)
      else
        @plans = @hbx_enrollment.decorated_elected_plans(@coverage_kind)
      end

      build_same_plan_premiums
    end

    # for carrier search options
    carrier_profile_ids = @plans.map(&:carrier_profile_id).map(&:to_s).uniq
    @carrier_names_map = Organization.valid_carrier_names_filters.select{|k, v| carrier_profile_ids.include?(k)}
  end

  def build_same_plan_premiums
    enrolled_plans = @plans.collect(&:id) & @enrolled_hbx_enrollment_plan_ids
    if enrolled_plans.present?
      enrolled_plans = enrolled_plans.collect{|p| Plan.find(p)}

      plan_selection = PlanSelection.new(@hbx_enrollment, @hbx_enrollment.plan)
      same_plan_enrollment = plan_selection.same_plan_enrollment

      if @hbx_enrollment.is_shop?
        ref_plan = (@hbx_enrollment.coverage_kind == "health" ? @benefit_group.reference_plan : @benefit_group.dental_reference_plan)

        @enrolled_plans = enrolled_plans.collect{|plan|
          @benefit_group.decorated_plan(plan, same_plan_enrollment, ref_plan)
        }
      else
        @enrolled_plans = same_plan_enrollment.calculate_costs_for_plans(enrolled_plans)
      end

      @enrolled_plans.each do |enrolled_plan|
        if plan_index = @plans.index{|e| e.id == enrolled_plan.id}
          @plans[plan_index] = enrolled_plan
        end
      end
    end
  end

  def thousand_ceil(num)
    return 0 if num.blank?
    (num.fdiv 1000).ceil * 1000
  end

  def set_kind_for_market_and_coverage
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
  end

  def get_aptc_info_from_session(hbx_enrollment)
    @shopping_tax_household = get_shopping_tax_household_from_person(@person, hbx_enrollment.effective_on.year) if @person.present?
    if @shopping_tax_household.present?
      @max_aptc = session[:max_aptc].to_f
      @elected_aptc = session[:elected_aptc].to_f
    else
      @max_aptc = 0
      @elected_aptc = 0
    end
  end

  def can_apply_aptc?(plan)
    @shopping_tax_household.present? and @elected_aptc > 0 and plan.present? and plan.can_use_aptc?
  end

  def set_elected_aptc_by_params(elected_aptc)
    if session[:elected_aptc].to_f != elected_aptc.to_f
      session[:elected_aptc] = elected_aptc.to_f
    end
  end
end
