class Insured::PlanShoppingsController < ApplicationController
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include Acapi::Notifiers
  extend Acapi::Notifiers
  include Aptc

  before_action :set_current_person, :only => [:receipt, :thankyou, :waive, :show, :plans, :checkout, :terminate, :plan_selection_callback]
  before_action :set_kind_for_market_and_coverage, only: [:thankyou, :show, :plans, :checkout, :receipt, :set_elected_aptc, :plan_selection_callback]

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
    plan_selection.apply_aptc_if_needed(@shopping_tax_households, @elected_aptc, @max_aptc)
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
      family = @person.primary_family
      @shopping_tax_households = get_shopping_tax_households_from_person(@person, @enrollment.effective_on.year) if family.present? && !family.application_in_progress.present?
      applied_aptc = @enrollment.applied_aptc_amount if @enrollment.applied_aptc_amount > 0
      @market_kind = "individual"
    end

    @plan = @enrollment.build_plan_premium(qhp_plan: plan, apply_aptc: applied_aptc.present?, elected_aptc: applied_aptc, tax_households: @shopping_tax_households)

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''

    send_receipt_emails if @person.emails.first
  end

  def thankyou
    set_elected_aptc_by_params(params[:elected_aptc]) if params[:elected_aptc].present?
    set_consumer_bookmark_url(family_account_path)
    set_admin_bookmark_url
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))
    @enrollment.set_special_enrollment_period

    if @enrollment.is_shop?
      @employer_profile = @enrollment.employer_profile
    else
      get_aptc_info_from_session(@enrollment)
    end

    @enrollment.reset_dates_on_previously_covered_members(@plan)
    @plan = @enrollment.build_plan_premium(qhp_plan: @plan, apply_aptc: can_apply_aptc?(@plan), elected_aptc: @elected_aptc, tax_households: @shopping_tax_households)
    @family = @person.primary_family

    #FIXME need to implement can_complete_shopping? for individual
    @enrollable = @market_kind == 'individual' ? true : @enrollment.can_complete_shopping?(qle: @enrollment.is_special_enrollment?)
    @waivable = @enrollment.can_complete_shopping?
    if params[:change_plan].present? 
     @change_plan =  params[:change_plan] 
    elsif @enrollment.is_special_enrollment?
      @change_plan = "change_plan"
    end
    if params[:enrollment_kind].present? 
      @enrollment_kind = params[:enrollment_kind] 
    elsif @enrollment.is_special_enrollment?
      @enrollment_kind = "sep"
    else
       @enrollment_kind = ""
    end
    flash.now[:error] = qualify_qle_notice unless @enrollment.can_select_coverage?(qle: @enrollment.is_special_enrollment?)

    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def waive
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    waiver_success = false

    begin
      if hbx_enrollment.shopping?
        @waiver_enrollment = hbx_enrollment
      else
        unless hbx_enrollment.waiver_enrollment_present?
          @waiver_enrollment = hbx_enrollment.construct_waiver_enrollment(params[:waiver_reason])
        end
      end

      if @waiver_enrollment.present?
        if @waiver_enrollment.may_waive_coverage?
          @waiver_enrollment.waiver_reason = params[:waiver_reason]
          @waiver_enrollment.waive_enrollment
        end

        if @waiver_enrollment.inactive?
          waiver_success = true
        end
      end

      if waiver_success
        redirect_to print_waiver_insured_plan_shopping_path(@waiver_enrollment), notice: "Waive Coverage Successful"
        trigger_notice_observer(@waiver_enrollment.employee_role, @waiver_enrollment, "employee_waiver_confirmation")
      else
        redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id), alert: "Waive Coverage Failed"
      end
    rescue => e
      log(e.message, :severity=>'error')
      redirect_to new_insured_group_selection_path(person_id: @person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id), alert: "Waive Coverage Failed"
    end
  end

  def print_waiver
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
  end

  def terminate
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    coverage_end_date = @person.primary_family.terminate_date_for_shop_by_enrollment(hbx_enrollment)
    hbx_enrollment.terminate_enrollment(coverage_end_date, params[:terminate_reason])

    if hbx_enrollment.coverage_terminated? || hbx_enrollment.coverage_termination_pending? || hbx_enrollment.coverage_canceled?
      hbx_enrollment.update_renewal_coverage
      household = @person.primary_family.active_household
      household.reload
      waiver_enrollment = household.hbx_enrollments.where(predecessor_enrollment_id: hbx_enrollment.id).first
      redirect_to print_waiver_insured_plan_shopping_path(waiver_enrollment), notice: "Waive Coverage Successful"
    else
      redirect_to :back
    end
  end

  def show
    set_consumer_bookmark_url(family_account_path) if params[:market_kind] == 'individual'
    set_admin_bookmark_url if params[:market_kind] == 'individual'
    set_employee_bookmark_url(family_account_path) if params[:market_kind] == 'shop'
    set_resident_bookmark_url(family_account_path) if params[:market_kind] == 'coverall'
    hbx_enrollment_id = params.require(:id)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    @family_member_ids = params[:family_member_ids]
    year = HbxEnrollment.find(hbx_enrollment_id).effective_on.year
    @family_member_ids = @family_member_ids.collect { |k,v| v}
    shopping_tax_households = get_tax_households_from_family_members(@person, @family_member_ids, year) if !@person.primary_family.application_in_progress.present?
  
    set_plans_by(hbx_enrollment_id: hbx_enrollment_id)
    if shopping_tax_households.present? && @hbx_enrollment.coverage_kind == "health" && @hbx_enrollment.kind == 'individual'
      @tax_households = shopping_tax_households
      @max_aptc = total_aptc_on_tax_households(shopping_tax_households, @hbx_enrollment)
      session[:max_aptc] = @max_aptc
      @elected_aptc = session[:elected_aptc] = @max_aptc * 0.85
    else
      session[:max_aptc] = 0
      session[:elected_aptc] = 0
    end

    if params[:market_kind] == 'shop' && plan_match_dc
      is_congress_employee = @hbx_enrollment.benefit_group.is_congress
      @dc_checkbook_url = ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment,is_congress_employee).generate_url
    elsif @hbx_enrollment.kind == "individual"
      if @hbx_enrollment.effective_on.year == Settings.checkbook_services.current_year
        plan_comparision_obj = ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment)
        plan_comparision_obj.elected_aptc = session[:elected_aptc]
        @dc_individual_checkbook_url = plan_comparision_obj.generate_url
      elsif @hbx_enrollment.effective_on.year == Settings.checkbook_services.previous_year 
        @dc_individual_checkbook_previous_year = Rails.application.config.checkbook_services_base_url + "/hie/dc/"+ Settings.checkbook_services.previous_year.to_s + "/"
      end
   end
    @carriers = @carrier_names_map.values
    @waivable = @hbx_enrollment.try(:can_complete_shopping?)
    @max_total_employee_cost = thousand_ceil(@plans.map(&:total_employee_cost).map(&:to_f).max)
    @max_deductible = thousand_ceil(@plans.map(&:deductible).map {|d| d.is_a?(String) ? d.gsub(/[$,]/, '').to_i : 0}.max)
  end

  def plan_selection_callback
    selected_plan= Plan.where(:hios_id=> params[:hios_id], active_year: Settings.checkbook_services.current_year).first
    if selected_plan.present?
      redirect_to thankyou_insured_plan_shopping_path({plan_id: selected_plan.id.to_s, id: params[:id],coverage_kind: params[:coverage_kind], market_kind: params[:market_kind], change_plan: params[:change_plan]})
    else
      redirect_to insured_plan_shopping_path(request.params), :flash => "No plan selected"
    end
  end

  def set_elected_aptc
    session[:elected_aptc] = params[:elected_aptc].to_f
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
    plan_comparision_obj = ::Services::CheckbookServices::PlanComparision.new(@hbx_enrollment)
    plan_comparision_obj.elected_aptc =  session[:elected_aptc]
    checkbook_url = plan_comparision_obj.generate_url
    render json: {message: 'ok',checkbook_url: "#{checkbook_url}" }
  end

  def plans
    @family_member_ids = params[:family_member_ids]
    set_consumer_bookmark_url(family_account_path)
    set_admin_bookmark_url
    set_plans_by(hbx_enrollment_id: params.require(:id))
    application = @person.primary_family.active_approved_application
    if (application.present? && application.tax_households.present?) || @person.primary_family.active_household.latest_active_tax_households.present?
      if is_eligibility_determined_and_not_csr_100?(@person, params[:family_member_ids])
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

  def is_eligibility_determined_and_not_csr_100?(person, family_member_ids)
    primary_family = person.primary_family
    csr_kinds = []

    if primary_family.application_in_progress.present?
      csr_kinds << "csr_100"
    else
      if !primary_family.active_household.latest_active_tax_households.map(&:application_id).include?(nil)
        if primary_family.active_approved_application.present?
          family_member_ids.each do |member_id|
            applicant = primary_family.active_approved_application.active_applicants.where(family_member_id: member_id).first

            if applicant.non_ia_eligible?
              return false
            end
            tax_household = primary_family.active_approved_application.tax_household_for_family_member(member_id)
            csr_kind = primary_family.active_approved_application.current_csr_eligibility_kind(tax_household.id)
            csr_kinds << csr_kind if EligibilityDetermination::CSR_KINDS.include? csr_kind
          end
        end
      else
        family_member_ids.each do |member_id|
          primary_family.active_household.latest_active_tax_households.each do |thh|
            tax_household_member = thh.tax_household_members.where(applicant_id: member_id).first
            if tax_household_member.present?
              if tax_household_member.non_ia_eligible?
                return false
              end
              csr_kind = thh.current_csr_eligibility_kind
              csr_kinds << csr_kind if EligibilityDetermination::CSR_KINDS.include? csr_kind
            end
          end
        end
      end
    end

    !csr_kinds.include? "csr_100"
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
    if @person.nil?
      @enrolled_hbx_enrollment_plan_ids = []
    else
      covered_plan_year = @person.active_employee_roles.first.employer_profile.plan_years.detect { |py| (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(@person.primary_family.current_sep.try(:effective_on))} if @person.active_employee_roles.first.present?
      if covered_plan_year.present?
        id_list = covered_plan_year.benefit_groups.map(&:id)
        @enrolled_hbx_enrollment_plan_ids = @person.primary_family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).effective_desc.map(&:plan).compact.map(&:id)
      else
        @enrolled_hbx_enrollment_plan_ids = @person.primary_family.enrolled_hbx_enrollments.map(&:plan).map(&:id)
      end
    end

    family_member_ids = @family_member_ids

    Caches::MongoidCache.allocate(CarrierProfile)
    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    @enrolled_hbx_enrollment_plan_ids = @hbx_enrollment.family.currently_enrolled_plans_ids(@hbx_enrollment)

    if @hbx_enrollment.blank?
      @plans = []
    else
      if @hbx_enrollment.is_shop?
        @benefit_group = @hbx_enrollment.benefit_group
        @plans = @benefit_group.decorated_elected_plans(@hbx_enrollment, @coverage_kind)
      else
        @plans = @hbx_enrollment.decorated_elected_plans(@coverage_kind, @market_kind)
      end

      build_same_plan_premiums
    end

    # for carrier search options
    carrier_profile_ids = @plans.map(&:carrier_profile_id).map(&:to_s).uniq
    @carrier_names_map = Organization.valid_carrier_names_filters.select{|k, v| carrier_profile_ids.include?(k)}
  end

  def enrolled_plans_by_hios_id_and_active_year
    @enrolled_hbx_enrollment_plans = @hbx_enrollment.family.currently_enrolled_plans(@hbx_enrollment)
    if !@hbx_enrollment.is_shop?
      (@plans.select{|plan| @enrolled_hbx_enrollment_plans.select {|existing_plan| plan.is_same_plan_by_hios_id_and_active_year?(existing_plan) }.present? }).collect(&:id)
    else
      (@plans.collect(&:id) & @enrolled_hbx_enrollment_plan_ids)
    end
  end

  def build_same_plan_premiums
    enrolled_plans = enrolled_plans_by_hios_id_and_active_year
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
        case  @hbx_enrollment.is_shop?
        when false
          if plan_index = @plans.index{|e| e.is_same_plan_by_hios_id_and_active_year?(enrolled_plan) }
            @plans[plan_index] = enrolled_plan
          end
        else
          if plan_index = @plans.index{|e| e.id == enrolled_plan.id}
            @plans[plan_index] = enrolled_plan
          end
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
    @shopping_tax_households = get_shopping_tax_households_from_person(@person, hbx_enrollment.effective_on.year) if @person.present? && @person.primary_family.present? && !@person.primary_family.application_in_progress.present?
    if @shopping_tax_households.present?
      @max_aptc = session[:max_aptc].to_f
      @elected_aptc = session[:elected_aptc].to_f
    else
      @max_aptc = 0
      @elected_aptc = 0
    end
  end

  def can_apply_aptc?(plan)
    @shopping_tax_households.present? and @elected_aptc > 0 and plan.present? and plan.can_use_aptc?
  end

  def set_elected_aptc_by_params(elected_aptc)
    if session[:elected_aptc].to_f != elected_aptc.to_f
      session[:elected_aptc] = elected_aptc.to_f
    end
  end
end