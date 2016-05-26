class Insured::FamiliesController < FamiliesController
  include VlpDoc
  include Acapi::Notifiers

  before_action :init_qualifying_life_events, only: [:home, :manage_family, :find_sep]
  before_action :check_for_address_info, only: [:find_sep, :home]
  before_action :check_employee_role

  def home
    set_flash_by_announcement
    set_bookmark_url

    log("#3717 person_id: #{@person.id}, params: #{params.to_s}, request: #{request.env.inspect}", {:severity => "error"}) if @family.blank?

    @hbx_enrollments = @family.enrollments.order(effective_on: :desc, submitted_at: :desc, coverage_kind: :desc) || []

    @enrollment_filter = @family.enrollments_for_display

    @waived_enrollment_filter = @family.waivers_for_display

    valid_display_enrollments = Array.new
    @enrollment_filter.each  { |e| valid_display_enrollments.push e['hbx_enrollment']['_id'] }

    valid_display_waived_enrollments = Array.new
    @waived_enrollment_filter.each  { |e| valid_display_waived_enrollments.push e['hbx_enrollment']['_id'] }


    log("#3860 person_id: #{@person.id}", {:severity => "error"}) if @hbx_enrollments.any?{|hbx| hbx.plan.blank?}
    @waived_hbx_enrollments = @family.active_household.hbx_enrollments.waived.to_a
    update_changing_hbxs(@hbx_enrollments)

    # Filter out enrollments for display only
    @hbx_enrollments = @hbx_enrollments.reject { |r| !valid_display_enrollments.include? r._id }
    @waived_hbx_enrollments = @waived_hbx_enrollments.each.reject { |r| !valid_display_waived_enrollments.include? r._id }

    hbx_enrollment_kind_and_years = @hbx_enrollments.inject(Hash.new { [] }) do |memo, enrollment|
      memo[enrollment.coverage_kind] += [ enrollment.effective_on.year ] if enrollment.aasm_state == 'coverage_selected' && enrollment.is_shop?
      memo[enrollment.coverage_kind].compact
      memo
    end


    @waived_hbx_enrollments = @waived_hbx_enrollments.select {|h| !hbx_enrollment_kind_and_years[h.coverage_kind].include?(h.effective_on.year) }
    @waived = @family.coverage_waived? && @waived_hbx_enrollments.present?

    @employee_role = @person.active_employee_roles.first
    @tab = params['tab']
    respond_to do |format|
      format.html
    end
  end

  def manage_family

    set_bookmark_url
    @family_members = @family.active_family_members
    # @employee_role = @person.employee_roles.first
    @tab = params['tab']


    respond_to do |format|
      format.html
    end
  end

  def brokers
    @tab = params['tab']

    if @person.active_employee_roles.present?
      @employee_role = @person.active_employee_roles.first
    end
  end

  def find_sep
    @hbx_enrollment_id = params[:hbx_enrollment_id]
    @change_plan = params[:change_plan]
    @employee_role_id = params[:employee_role_id]


    @next_ivl_open_enrollment_date = HbxProfile.current_hbx.try(:benefit_sponsorship).try(:renewal_benefit_coverage_period).try(:open_enrollment_start_on)

    @market_kind = (params[:employee_role_id].present? && params[:employee_role_id] != 'None') ? 'shop' : 'individual'

    render :layout => 'application'
  end

  def record_sep
    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.save
    end

    action_params = {person_id: @person.id, consumer_role_id: @person.consumer_role.try(:id), employee_role_id: params[:employee_role_id], enrollment_kind: 'sep'}
    if @family.enrolled_hbx_enrollments.any?
      action_params.merge!({change_plan: "change_plan"})
    end

    redirect_to new_insured_group_selection_path(action_params)
  end

  def personal
    @tab = params['tab']

    @family_members = @family.active_family_members
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@person.consumer_role) if @person.has_active_consumer_role?
    @person.consumer_role.build_nested_models_for_person if @person.has_active_consumer_role?
    respond_to do |format|
      format.html
    end
  end

  def inbox
    @tab = params['tab']
    @folder = params[:folder] || 'Inbox'
    @sent_box = false
  end

  def verification
    @family_members = @person.primary_family.family_members.active
  end

  def check_qle_date
    @qle_date = Date.strptime(params[:date_val], "%m/%d/%Y")
    start_date = TimeKeeper.date_of_record - 30.days
    end_date = TimeKeeper.date_of_record + 30.days

    if params[:qle_id].present?
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @qle_aptc_block = @family.is_blocked_by_qle_and_assistance?(@qle, session["individual_assistance_path"])
      start_date = TimeKeeper.date_of_record - @qle.post_event_sep_in_days.try(:days)
      end_date = TimeKeeper.date_of_record + @qle.pre_event_sep_in_days.try(:days)
      @effective_on_options = @qle.employee_gaining_medicare(@qle_date) if @qle.is_dependent_loss_of_coverage?
    end

    @qualified_date = (start_date <= @qle_date && @qle_date <= end_date) ? true : false
  end

  def purchase
    @enrollment = @family.try(:latest_household).try(:hbx_enrollments).active.last

    if @enrollment.present?
      plan = @enrollment.try(:plan)
      if @enrollment.is_shop?
        @benefit_group = @enrollment.benefit_group
        @reference_plan = @enrollment.coverage_kind == 'dental' ? @benefit_group.dental_reference_plan : @benefit_group.reference_plan

        if @benefit_group.is_congress
          @plan = PlanCostDecoratorCongress.new(plan, @enrollment, @benefit_group)
        else
          @plan = PlanCostDecorator.new(plan, @enrollment, @benefit_group, @reference_plan)
        end
      else
        @plan = UnassistedPlanCostDecorator.new(plan, @enrollment)
      end

      begin
        @plan.name
      rescue => e
        log("#{e.message};  #3742 plan: #{@plan}, family_id: #{@family.id}, hbx_enrollment_id: #{@enrollment.id}", {:severity => "error"})
      end

      @enrollable = @family.is_eligible_to_enroll?

      @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
      @terminate = params[:terminate].present? ? params[:terminate] : ''
      render :layout => 'application'
    else
      redirect_to :back
    end
  end

  def unblock
    @family = Family.find(params[:id])
    @family.set(status: "aptc_unblock")
  end

  def delete_consumer_broker
    @family = Family.find(params[:id])
    if @family.current_broker_agency.destroy
      redirect_to :action => "home" , flash: {notice: "Successfully deleted."}
    end
  end

  private

  def check_employee_role
    @employee_role = @person.active_employee_roles.first
  end

  def init_qualifying_life_events
    begin
      raise if @person.nil?
    rescue => e
      message = "no person in init_qualifying_life_events"
      message = message + "stacktrace: #{e.backtrace}"
      log(message, {:severity => "error"})
      raise e
    end
    @qualifying_life_events = []
    if @person.has_multiple_roles?
      @multiroles = @person.has_multiple_roles?
      @manually_picked_role = params[:market] ? params[:market] : "shop_market_events"
      @qualifying_life_events += QualifyingLifeEventKind.send @manually_picked_role if @manually_picked_role
    else
      if @person.active_employee_roles.present?
        @qualifying_life_events += QualifyingLifeEventKind.shop_market_events
      else @person.consumer_role.present?
      @qualifying_life_events += QualifyingLifeEventKind.individual_market_events
      end
    end

  end

  def check_for_address_info
    if @person.has_active_employee_role?
      if @person.addresses.blank?
        redirect_to edit_insured_employee_path(@person.active_employee_roles.first)
      end
    elsif @person.has_active_consumer_role?
      if !(@person.addresses.present? || @person.no_dc_address.present? || @person.no_dc_address_reason.present?)
        redirect_to edit_insured_consumer_role_path(@person.consumer_role)
      elsif @person.user && (!@person.user.identity_verified? && !@person.user.idp_verified?)
        redirect_to ridp_agreement_insured_consumer_role_index_path
      end
    end
  end

  def update_changing_hbxs(hbxs)
    if hbxs.present?
      changing_hbxs = hbxs.changing
      changing_hbxs.update_all(changing: false) if changing_hbxs.present?
    end
  end
end
