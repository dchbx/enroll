# frozen_string_literal: true

class Insured::FamilyMembersController < ApplicationController
  include VlpDoc
  include ApplicationHelper

  before_action :permit_dependent_person_params, only: %i[create update]

  before_action :set_current_person, :set_family
  before_action :set_dependent, only: [:destroy, :show, :edit, :update]

  def index
    set_bookmark_url
    set_admin_bookmark_url(insured_family_members_path)
    @type = (params[:employee_role_id].present? && params[:employee_role_id] != 'None') ? "employee" : "consumer"

    if params[:resident_role_id].present? && params[:resident_role_id]
      @type = "resident"
      @resident_role = ResidentRole.find(params[:resident_role_id])
      @family.hire_broker_agency(current_user.person.broker_role.try(:id))
      redirect_to resident_index_insured_family_members_path(:resident_role_id => @person.resident_role.id, :change_plan => params[:change_plan], :qle_date => params[:qle_date], :qle_id => params[:qle_id], :effective_on_kind => params[:effective_on_kind], :qle_reason_choice => params[:qle_reason_choice], :commit => params[:commit])
    end

    if @type == "employee"
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    elsif @type == "consumer"
      @consumer_role = @person.consumer_role
      @family.hire_broker_agency(current_user.person.broker_role.try(:id))
    end
    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''

    if params[:sep_id].present?
      @sep = @family.special_enrollment_periods.find(params[:sep_id])
      @sep = duplicate_sep(@sep) if @sep.submitted_at.to_date != TimeKeeper.date_of_record
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      @change_plan = 'change_by_qle'
      @change_plan_date = @sep.qle_on
    elsif params[:qle_id].present? && !params[:shop_for_plan]

      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.market_kind = qle.market_kind == "individual" ? "ivl" : qle.market_kind
      special_enrollment_period.qle_answer = params[:qle_reason_choice] if params[:qle_reason_choice].present?
      special_enrollment_period.save
      @market_kind = qle.market_kind
    end
    @market_kind = params[:market_kind] if params[:market_kind].present?
    if request.referer.present?
      @prev_url_include_intractive_identity = request.referer.include?("interactive_identity_verifications")
      @prev_url_include_consumer_role_id = request.referer.include?("consumer_role_id")
    else
      @prev_url_include_intractive_identity = false
      @prev_url_include_consumer_role_id = false
    end
  end

  def new
    @dependent = ::Forms::FamilyMember.new(:family_id => params.require(:family_id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @dependent = ::Forms::FamilyMember.new(params[:dependent])

    @address_errors = validate_address_params(params)
    if Family.find(@dependent.family_id).primary_applicant.person.resident_role?
      if @address_errors.blank? && @dependent.save
        @created = true
        respond_to do |format|
          format.html { render 'show_resident' }
          format.js { render 'show_resident' }
        end
      else
        init_address_for_dependent
        respond_to do |format|
          format.html { render 'new_resident_dependent' }
          format.js { render 'new_resident_dependent' }
        end
      end
      return
    end
    if @address_errors.blank? && @dependent.save && update_vlp_documents(@dependent.family_member.try(:person).try(:consumer_role), 'dependent', @dependent)
      @created = true
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@dependent.family_member.try(:person).try(:consumer_role))
      init_address_for_dependent
      respond_to do |format|
        format.html { render 'new' }
        format.js { render 'new' }
      end
    end
  end

  def destroy
    @dependent.destroy!
    respond_to do |format|
      format.html { render 'index' }
      format.js { render 'destroyed' }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(consumer_role) if consumer_role.present?

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @address_errors = validate_address_params(params)

    if @dependent.family_member.try(:person).present? && @dependent.family_member.try(:person).is_resident_role_active?
      if @address_errors.blank? && @dependent.update_attributes(params[:dependent])
        respond_to do |format|
          format.html { render 'show_resident' }
          format.js { render 'show_resident' }
        end
      else
        init_address_for_dependent
        respond_to do |format|
          format.html { render 'edit_resident_dependent' }
          format.js { render 'edit_resident_dependent' }
        end
      end
      return
    end
    consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
    @info_changed, @dc_status = sensitive_info_changed?(consumer_role)
    if @address_errors.blank? && @dependent.update_attributes(params[:dependent]) && update_vlp_documents(consumer_role, 'dependent', @dependent)
      consumer_role = @dependent.family_member.try(:person).try(:consumer_role)
      consumer_role&.check_for_critical_changes(
        @dependent.family_member.family,
        info_changed: @info_changed,
        is_homeless: params[:dependent]["is_homeless"],
        is_temporarily_out_of_state: params[:dependent]["is_temporarily_out_of_state"],
        dc_status: @dc_status
      )
      if consumer_role.present? && !params[:dependent][:is_applying_coverage].nil?
        consumer_role.update_attribute(
          :is_applying_coverage,
          params[:dependent][:is_applying_coverage]
        )
      end
      respond_to do |format|
        format.html { render 'show' }
        format.js { render 'show' }
      end
    else
      @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(consumer_role) if consumer_role.present?
      init_address_for_dependent
      respond_to do |format|
        format.html { render 'edit' }
        format.js { render 'edit' }
      end
    end
  end

  def resident_index
    set_bookmark_url
    set_admin_bookmark_url(resident_index_insured_family_members_path)
    @resident_role = @person.resident_role
    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''

    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      @effective_on_date = special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.qle_answer = params[:qle_reason_choice] if params[:qle_reason_choice].present?
      special_enrollment_period.save
      @market_kind = "coverall"
    end

    if request.referer.present?
      @prev_url_include_intractive_identity = request.referer.include?("interactive_identity_verifications")
      @prev_url_include_consumer_role_id = request.referer.include?("consumer_role_id")
    else
      @prev_url_include_intractive_identity = false
      @prev_url_include_consumer_role_id = false
    end
  end

  def new_resident_dependent
    @dependent = ::Forms::FamilyMember.new(:family_id => params.require(:family_id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit_resident_dependent
    @dependent = ::Forms::FamilyMember.find(params.require(:id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show_resident_dependent
    @dependent = ::Forms::FamilyMember.find(params.require(:id))
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def permit_dependent_person_params
    params.require(:dependent).permit!
  end

  def set_family
    @family = @person.try(:primary_family)
  end

  def init_address_for_dependent
    if @dependent.same_with_primary == "true"
      @dependent.addresses = [Address.new(kind: 'home'), Address.new(kind: 'mailing')]
    elsif @dependent.addresses.is_a? ActionController::Parameters
      addresses = []
      @dependent.addresses.each do |_k, address|
        addresses << Address.new(address.permit!)
      end
      @dependent.addresses = addresses
    end
  end

  def validate_address_params(params)
    return [] if params[:dependent][:same_with_primary] == 'true'

    errors_array = []
    clean_address_params = params[:dependent][:addresses].reject{ |_key, value| value[:address_1].blank? && value[:city].blank? && value[:state].blank? && value[:zip].blank? }
    param_indexes = clean_address_params.keys.compact
    param_indexes.each do |param_index|
      permitted_address_params = clean_address_params.require(param_index).permit(:address_1, :address_2, :city, :kind, :state, :zip)
      result = Validators::AddressContract.new.call(permitted_address_params.to_h)
      errors_array << result.errors.to_h if result.failure?
    end
    errors_array
  end

  def duplicate_sep(sep)
    sp = SpecialEnrollmentPeriod.new(sep.attributes.except("effective_on", "submitted_at", "_id"))
    sp.qualifying_life_event_kind = sep.qualifying_life_event_kind    # initiate sep dates
    @family.special_enrollment_periods << sp
    sp.save
    sp
  end

  def set_dependent
    @dependent = ::Forms::FamilyMember.find(params.require(:id))
  end
end
