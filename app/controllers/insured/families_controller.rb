class Insured::FamiliesController < FamiliesController
  include VlpDoc
  include Acapi::Notifiers
  include ApplicationHelper

  before_action :updateable?, only: [:delete_consumer_broker, :record_sep, :purchase, :upload_notice]
  before_action :init_qualifying_life_events, only: [:home, :manage_family, :find_sep]
  before_action :check_for_address_info, only: [:find_sep, :home]
  before_action :check_employee_role
  before_action :find_or_build_consumer_role, only: [:home]
  before_action :calculate_dates, only: [:check_move_reason, :check_marriage_reason, :check_insurance_reason]

  def home
    authorize @family, :show?
    build_employee_role_by_census_employee_id
    set_flash_by_announcement
    set_bookmark_url
    @active_sep = @family.latest_active_sep

    log("#3717 person_id: #{@person.id}, params: #{params.to_s}, request: #{request.env.inspect}", {:severity => "error"}) if @family.blank?

    @hbx_enrollments = @family.enrollments.order(effective_on: :desc, submitted_at: :desc, coverage_kind: :desc) || []
    @enrollment_filter = @family.enrollments_for_display

    valid_display_enrollments = Array.new
    @enrollment_filter.each  { |e| valid_display_enrollments.push e['hbx_enrollment']['_id'] }

    log("#3860 person_id: #{@person.id}", {:severity => "error"}) if @hbx_enrollments.any?{|hbx| !hbx.is_coverage_waived? && hbx.plan.blank?}
    update_changing_hbxs(@hbx_enrollments)

    @hbx_enrollments = @hbx_enrollments.reject{ |r| !valid_display_enrollments.include? r._id }

    @employee_role = @person.active_employee_roles.first
    @tab = params['tab']
    @family_members = @family.active_family_members

    respond_to do |format|
      format.html
    end
  end

  def manage_family
    set_bookmark_url
    @family_members = @family.active_family_members
    @resident = @person.is_resident_role_active?
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

    if (params[:resident_role_id].present? && params[:resident_role_id])
      @resident_role_id = params[:resident_role_id]
    else
      @resident_role_id = @person.try(:resident_role).try(:id)
    end

    @next_ivl_open_enrollment_date = HbxProfile.current_hbx.try(:benefit_sponsorship).try(:renewal_benefit_coverage_period).try(:open_enrollment_start_on)

    @market_kind = (params[:employee_role_id].present? && params[:employee_role_id] != 'None') ? 'shop' : 'individual'
    if ((params[:resident_role_id].present? && params[:resident_role_id]) || @resident_role_id)
      @market_kind = "coverall"
    end
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

    action_params = {person_id: @person.id, consumer_role_id: @person.consumer_role.try(:id), employee_role_id: params[:employee_role_id], enrollment_kind: 'sep', effective_on_date: special_enrollment_period.effective_on, qle_id: qle.id}
    if @family.enrolled_hbx_enrollments.any?
      action_params.merge!({change_plan: "change_plan"})
    end

    redirect_to new_insured_group_selection_path(action_params)
  end

  def personal
    @tab = params['tab']

    @family_members = @family.active_family_members
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@person.consumer_role) if @person.is_consumer_role_active?
    @person.consumer_role.build_nested_models_for_person if @person.is_consumer_role_active?
    @person.resident_role.build_nested_models_for_person if @person.is_resident_role_active?
    @resident = @person.resident_role.present?
    respond_to do |format|
      format.html
    end
  end

  def inbox
    @tab = params['tab']
    @folder = params[:folder] || 'Inbox'
    @sent_box = false
    @provider = @person
  end

  def verification
    @family_members = @person.primary_family.family_members.active
  end

  def upload_application
    @family_members = @person.primary_family.family_members.active
  end

  def check_qle_date
    @qle_date = Date.strptime(params[:date_val], "%m/%d/%Y")
    start_date = TimeKeeper.date_of_record - 30.days
    end_date = TimeKeeper.date_of_record + 30.days

    if params[:qle_id].present?
      @qle = QualifyingLifeEventKind.find(params[:qle_id])
      start_date = TimeKeeper.date_of_record - @qle.post_event_sep_in_days.try(:days)
      end_date = TimeKeeper.date_of_record + @qle.pre_event_sep_in_days.try(:days)
      @effective_on_options = @qle.employee_gaining_medicare(@qle_date) if @qle.is_dependent_loss_of_coverage?
      @qle_reason_val = params[:qle_reason_val] if params[:qle_reason_val].present?
      @qle_end_on = @qle_date + @qle.post_event_sep_in_days.try(:days)
    end

    @qualified_date = (start_date <= @qle_date && @qle_date <= end_date) ? true : false
    if @person.has_active_employee_role? && !(@qle.present? && @qle.individual?)
      @future_qualified_date = (@qle_date > TimeKeeper.date_of_record) ? true : false
    end

    if @person.resident_role?
      @resident_role_id = @person.resident_role.id
    end

    if ((@qle.present? && @qle.shop?) && !@qualified_date)
      sep_request_denial_notice
    elsif is_ee_sep_request_accepted?
      ee_sep_request_accepted_notice
    end
  end

  def check_move_reason
  end

  def check_insurance_reason
  end

  def check_marriage_reason
  end

  def purchase
    if params[:hbx_enrollment_id].present?
      @enrollment = HbxEnrollment.find(params[:hbx_enrollment_id])
    else
      @enrollment = @family.active_household.hbx_enrollments.active.last if @family.present?
    end

    if @enrollment.present?
      @enrollment.reset_dates_on_previously_covered_members
      @plan = @enrollment.build_plan_premium

      begin
        @plan.name
      rescue => e
        log("#{e.message};  #3742 plan: #{@plan}, family_id: #{@family.id}, hbx_enrollment_id: #{@enrollment.id}", {:severity => "error"})
      end

      @enrollable = @family.is_eligible_to_enroll?

      @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
      @terminate = params[:terminate].present? ? params[:terminate] : ''
      @terminate_date = @family.terminate_date_for_shop_by_enrollment(@enrollment) if @terminate.present?
      @terminate_reason = params[:terminate_reason] || ''
      render :layout => 'application'
    else
      redirect_to :back
    end
  end

  # admin manually uploads a notice for person
  def upload_notice

    if (!params.permit![:file]) || (!params.permit![:subject])
      flash[:error] = "File or Subject not provided"
      redirect_to(:back)
      return
    elsif file_content_type != 'application/pdf'
      flash[:error] = "Please upload a PDF file. Other file formats are not supported."
      redirect_to(:back)
      return
    end

    doc_uri = Aws::S3Storage.save(file_path, 'notices')

    if doc_uri.present?
      notice_document = Document.new({title: file_name, creator: "hbx_staff", subject: "notice", identifier: doc_uri,
                                      format: file_content_type})
      begin
        @person.documents << notice_document
        @person.save!
        send_notice_upload_notifications(notice_document, params.permit![:subject])
        flash[:notice] = "File Saved"
      rescue => e
        flash[:error] = "Could not save file."
      end
    else
      flash[:error] = "Could not save file."
    end

    redirect_to(:back)
    return
  end

  # displays the form to upload a notice for a person
  def upload_notice_form
    @notices = @person.documents.where(subject: 'notice')
  end

  def delete_consumer_broker
    @family = Family.find(params[:id])
    if @family.current_broker_agency.destroy
      redirect_to :action => "home" , flash: {notice: "Successfully deleted."}
    end
  end

  def sep_request_denial_notice
    begin
      ShopNoticesNotifierJob.perform_later(@person.active_employee_roles.first.census_employee.id.to_s, "sep_request_denial_notice")
    rescue Exception => e
      log("#{e.message}; person_id: #{@person.id}")
    end
  end

  def transition_family_members
    @row_id = params[:family_actions_id]
    @family_members = @family.active_family_members
    @non_shop_market_kinds = Person::NON_SHOP_ROLES
    respond_to do |format|
      format.js { render "insured/families/transition_family_members" }
    end
  end

  def transition_family_members_update
    @row_id = params[:family_actions_id]

    params_parser = ::Forms::BulkActionsForAdmin.new(params)
    @result = params_parser.result
    @row = params_parser.row
    @family_id = params_parser.family_id
    params_parser.transition_family_members

    respond_to do |format|
      format.js { render :file => "insured/families/transition_family_members_result.js.erb"}
    end
  end
  
  def is_ee_sep_request_accepted?
    !@person.has_multiple_active_employers? && @qle.present? && @qle.shop?
  end

  def ee_sep_request_accepted_notice
    employee_role = @person.active_employee_roles.first
    if employee_role.present? && employee_role.census_employee.present?
      begin
        ShopNoticesNotifierJob.perform_later(employee_role.census_employee.id.to_s, "ee_sep_request_accepted_notice", {title: @qle.title, end_on: "#{@qle_end_on}", qle_on: "#{@qle_date}"} )
      rescue Exception => e
        Rails.logger.error{"Unable to deliver employee SEP accepted notice to person_id: #{@person.id} due to #{e.message}"}
      end
    end
  end

  private

  def updateable?
    authorize Family, :updateable?
  end

  def check_employee_role
    employee_role_id = (params[:employee_id].present? && params[:employee_id].include?('employee_role')) ? params[:employee_id].gsub("employee_role_", "") : nil

    @employee_role = employee_role_id.present? ? @person.active_employee_roles.detect{|e| e.id.to_s == employee_role_id} : @person.active_employee_roles.first
  end

  def build_employee_role_by_census_employee_id
    census_employee_id = (params[:employee_id].present? && params[:employee_id].include?('census_employee')) ? params[:employee_id].gsub("census_employee_", "") : nil
    return if census_employee_id.nil?

    census_employee = CensusEmployee.find_by(id: census_employee_id)
    if census_employee.present?
      census_employee.construct_employee_role_for_match_person
      @employee_role = census_employee.employee_role
      @person.reload
    end
  end

  def find_or_build_consumer_role
    @family.check_for_consumer_role
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
      if current_user.has_hbx_staff_role?
        @multiroles = @person.has_multiple_roles?
        @manually_picked_role = params[:market] ? params[:market] : "shop_market_events"
        @qualifying_life_events += QualifyingLifeEventKind.send @manually_picked_role + '_admin' if @manually_picked_role == "shop_market_events"
        @qualifying_life_events += QualifyingLifeEventKind.send @manually_picked_role + '_without_transition_member_action' if @manually_picked_role == "individual_market_events"
      else
        @multiroles = @person.has_multiple_roles?
        @manually_picked_role = params[:market] ? params[:market] : "shop_market_events"
        @qualifying_life_events += QualifyingLifeEventKind.send @manually_picked_role if @manually_picked_role
      end
    else
      if @person.active_employee_roles.present?
        if current_user.has_hbx_staff_role?
          @qualifying_life_events += QualifyingLifeEventKind.shop_market_events_admin
        else
          @qualifying_life_events += QualifyingLifeEventKind.shop_market_events
        end
      else @person.consumer_role.present?
        if current_user.has_hbx_staff_role?
          @qualifying_life_events += QualifyingLifeEventKind.individual_market_events_without_transition_member_action
        else
          @qualifying_life_events += QualifyingLifeEventKind.individual_market_events
        end
      end
    end
  end

  def check_for_address_info
    if @person.has_active_employee_role?
      if @person.addresses.blank?
        redirect_to edit_insured_employee_path(@person.active_employee_roles.first)
      end
    elsif @person.is_consumer_role_active?
      if !(@person.addresses.present? || @person.no_dc_address.present? || @person.no_dc_address_reason.present?)
        redirect_to edit_insured_consumer_role_path(@person.consumer_role)
      elsif @person.user && !@person.user.identity_verified?
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

  def file_path
    params.permit(:file)[:file].tempfile.path
  end

  def file_name
    params.permit![:file].original_filename
  end

  def file_content_type
    params.permit![:file].content_type
  end

  def send_notice_upload_notifications(notice, subject)
    notice_upload_email
    notice_upload_secure_message(notice, subject)
  end

  def notice_upload_email
    if (@person.consumer_role.present? && @person.consumer_role.can_receive_electronic_communication?) ||
      (@person.employee_roles.present? && (@person.employee_roles.map(&:contact_method) & ["Only Electronic communications", "Paper and Electronic communications"]).any?)
      UserMailer.generic_notice_alert(@person.first_name, "You have a new message from DC Health Link", @person.work_email_or_best).deliver_now
    end
  end

  def notice_upload_secure_message(notice, subject)
    body = "<br>You can download the notice by clicking this link " +
            "<a href=" + "#{authorized_document_download_path('Person', @person.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + subject + "</a>"

    @person.inbox.messages << Message.new(subject: subject, body: body, from: 'DC Health Link')
    @person.save!
  end

  def calculate_dates
    @qle_date = Date.strptime(params[:date_val], "%m/%d/%Y")
    @qle = QualifyingLifeEventKind.find(params[:qle_id])
    start_date = TimeKeeper.date_of_record - @qle.post_event_sep_in_days.try(:days)
    end_date = TimeKeeper.date_of_record + @qle.pre_event_sep_in_days.try(:days)
    @qualified_date = (start_date <= @qle_date && @qle_date <= end_date) ? true : false
    @qle_date_calc = @qle_date - Settings.aca.qle.with_in_sixty_days.days

    if @person.resident_role?
      @resident_role_id = @person.resident_role.id
    end

  end

end
