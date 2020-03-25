class Exchanges::HbxProfilesController < ApplicationController
  include Exchanges::HbxProfilesHelper
  include VlpDoc
  include ::DataTablesAdapter
  include ::DataTablesSearch
  include ::Pundit
  include ::SepAll
  include ::Config::AcaHelper

  before_action :permit_params, only: [:family_index_dt]
  before_action :modify_admin_tabs?, only: [:binder_paid, :transmit_group_xml]
  before_action :check_hbx_staff_role, except: [:request_help, :configuration, :show, :assister_index, :family_index, :update_cancel_enrollment, :update_terminate_enrollment, :identity_verification]
  before_action :set_hbx_profile, only: [:edit, :update, :destroy]
  before_action :view_the_configuration_tab?, only: [:configuration, :set_date]
  before_action :can_submit_time_travel_request?, only: [:set_date]
  before_action :find_hbx_profile, only: [:employer_index, :configuration, :broker_agency_index, :inbox, :show, :binder_index]
  #before_action :authorize_for, except: [:edit, :update, :destroy, :request_help, :staff_index, :assister_index]
  #before_action :authorize_for_instance, only: [:edit, :update, :destroy]
  before_action :check_csr_or_hbx_staff, only: [:family_index]
  before_action :find_benefit_sponsorship, only: [:oe_extendable_applications, :oe_extended_applications, :edit_open_enrollment, :extend_open_enrollment, :close_extended_open_enrollment, :edit_fein, :update_fein, :force_publish, :edit_force_publish]
  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  layout 'single_column'

  def index
    @organizations = Organization.exists(hbx_profile: true)
    @hbx_profiles = @organizations.map {|o| o.hbx_profile}
  end

  def oe_extendable_applications
    @benefit_applications  = @benefit_sponsorship.oe_extendable_benefit_applications
    @element_to_replace_id = params[:employer_actions_id]
  end

  def oe_extended_applications
    @benefit_applications  = @benefit_sponsorship.oe_extended_applications
    @element_to_replace_id = params[:employer_actions_id]
  end

  def edit_open_enrollment
    @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:id])
  end

  def extend_open_enrollment
    authorize HbxProfile, :can_extend_open_enrollment?
    @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:id])
    open_enrollment_end_date = Date.strptime(params["open_enrollment_end_date"], "%m/%d/%Y")
    ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(@benefit_application).extend_open_enrollment(open_enrollment_end_date)
    redirect_to exchanges_hbx_profiles_root_path, :flash => { :success => "Successfully extended employer(s) open enrollment." }
  end

  def close_extended_open_enrollment
    authorize HbxProfile, :can_extend_open_enrollment?
    @benefit_application = @benefit_sponsorship.benefit_applications.find(params[:id])
    ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(@benefit_application).end_open_enrollment(TimeKeeper.date_of_record)
    redirect_to exchanges_hbx_profiles_root_path, :flash => { :success => "Successfully closed employer(s) open enrollment." }
  end

  def new_benefit_application
    authorize HbxProfile, :can_create_benefit_application?
    @ba_form = BenefitSponsors::Forms::BenefitApplicationForm.for_new(new_ba_params)
    @element_to_replace_id = params[:employer_actions_id]
  end

  def create_benefit_application
    @ba_form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(create_ba_params)
    authorize @ba_form, :updateable?
    @save_errors = benefit_application_error_messages(@ba_form) unless @ba_form.save
    @element_to_replace_id = params[:employer_actions_id]
  end

  def edit_fein
    @organization = @benefit_sponsorship.organization
    @element_to_replace_id = params[:employer_actions_id]

    respond_to do |format|
      format.js { render "edit_fein" }
    end
  end

  def update_fein
    @organization = @benefit_sponsorship.organization
    @element_to_replace_id = params[:employer_actions_id]
    service_obj = ::BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(benefit_sponsorship: @benefit_sponsorship)
    update_fein_result_array = service_obj.update_fein(params['organizations_general_organization']['new_fein'])
    @result = update_fein_result_array[0]
    @errors_on_save = update_fein_result_array[1]
    if @errors_on_save
      respond_to { |format| format.js { render 'edit_fein' } }
    else
      respond_to { |format| format.js { render 'update_fein' } }
    end
  end

  def binder_paid
    if params[:ids]
      begin
        ::BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.set_binder_paid(params[:ids])
        flash["notice"] = "Successfully submitted the selected employer(s) for binder paid."
        render json: { status: 200, message: 'Successfully submitted the selected employer(s) for binder paid.' }
      rescue => e
        render json: { status: 500, message: 'An error occured while submitting employer(s) for binder paid.' }
      end
    end
    # Removed redirect because of Datatables. Send Results to Datatable Status
    #redirect_to exchanges_hbx_profiles_root_path
  end

  def transmit_group_xml
    HbxProfile.transmit_group_xml(params[:id].split)
    @employer_profile = EmployerProfile.find(params[:id])
    @fein = @employer_profile.fein
    start_on = @employer_profile.show_plan_year.start_on.strftime("%Y%m%d")
    end_on = @employer_profile.show_plan_year.end_on.strftime("%Y%m%d")
    @xml_submit_time = @employer_profile.xml_transmitted_timestamp
    v2_xml_generator =  V2GroupXmlGenerator.new([@fein], start_on, end_on)
    send_data v2_xml_generator.generate_xmls
  end

  def employer_index
    @q = params.permit(:q)[:q]
    @orgs = Organization.search(@q).exists(employer_profile: true)
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)

    @employer_profiles = @organizations.map {|o| o.employer_profile}

    respond_to do |format|
      format.html { render "employers/employer_profiles/index" }
    end
  end

  def disable_ssn_requirement
    @benfit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"_id".in => params[:ids])

    @benfit_sponsorships.each do |benfit_sponsorship|
      # logic for both Bulk Action drop down and action column drop down under data table
      if params[:can_update].present?
        if params[:can_update] == "disable"
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: true, ssn_disabled_on: TimeKeeper.datetime_of_record)
        else
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: false, ssn_enabled_on: TimeKeeper.datetime_of_record)
        end
      else
        if !benfit_sponsorship.is_no_ssn_enabled
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: true, ssn_disabled_on: TimeKeeper.datetime_of_record)
        else
          benfit_sponsorship.update_attributes(is_no_ssn_enabled: false, ssn_enabled_on: TimeKeeper.datetime_of_record)
        end
      end
    end
    redirect_to exchanges_hbx_profiles_root_path, :flash => { :success => "SSN/TIN requirement has been successfully updated for the roster of selected employer" }
  end

  def generate_invoice
    @benfit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"_id".in => params[:ids])
    @organizations = @benfit_sponsorships.map(&:organization)
    @employer_profiles = @organizations.flat_map(&:employer_profile)
    @employer_profiles.each do |employer_profile|
      employer_profile.trigger_model_event(:generate_initial_employer_invoice)
    end

    flash["notice"] = "Successfully submitted the selected employer(s) for invoice generation."
    #redirect_to exchanges_hbx_profiles_root_path

     respond_to do |format|
       format.js
     end
  end

  def edit_force_publish
    @element_to_replace_id = params[:employer_actions_id]
    @benefit_application = @benefit_sponsorship.benefit_applications.draft_state.last

    respond_to do |format|
     format.js
   end
  end

  def force_publish
    @element_to_replace_id = params[:employer_actions_id]
    @benefit_application   = @benefit_sponsorship.benefit_applications.draft_state.last

    if @benefit_application.present?
      @service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(@benefit_application)
      if @service.may_force_submit_application? || params[:publish_with_warnings] == 'true'
        @service.force_submit_application
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def employer_invoice
    # Dynamic Filter values for upcoming 30, 60, 90 days renewals
    @next_30_day = TimeKeeper.date_of_record.next_month.beginning_of_month
    @next_60_day = @next_30_day.next_month
    @next_90_day = @next_60_day.next_month

    @datatable = Effective::Datatables::BenefitSponsorsEmployerDatatable.new

    respond_to do |format|
      format.js
    end
  end

  def employer_datatable
  @datatable = Effective::Datatables::BenefitSponsorsEmployerDatatable.new
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/invoice.html.slim' }
      # TODO: Consider adding the following after the format.html.
      # Look at ticket 40578 and associated PR for reference.
      # format.js
    end
  end

def employer_poc

    # Dynamic Filter values for upcoming 30, 60, 90 days renewals
    @next_30_day = TimeKeeper.date_of_record.next_month.beginning_of_month
    @next_60_day = @next_30_day.next_month
    @next_90_day = @next_60_day.next_month

    @datatable = Effective::Datatables::EmployerDatatable.new
    render '/exchanges/hbx_profiles/employer_poc'
 #   respond_to do |format|
  #    format.html
   #   format.js
   # end
  end


  def staff_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(:$or => [{csr_role: {:$exists => true}}, {assister_role: {:$exists => true}}])
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/staff.html.erb' }
    end
  end

  def assister_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(assister_role: {:$exists =>true})
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def find_email(agent, role)
    if role == 'Broker'
      agent.try(:broker_role).try(:email).try(:address)
    else
      agent.try(:user).try(:email)
    end
  end

  def request_help
    role = nil
    if params[:type]
      cac_flag = params[:type] == 'CAC'
      match = CsrRole.find_by_name(params[:firstname], params[:lastname], cac_flag)
      if match.count > 0
        agent = match.first
        role = cac_flag ? 'Certified Applicant Counselor' : 'Customer Service Representative'
      end
    else
      if params[:broker].present?
        agent = Person.find(params[:broker])
        broker_role_id = agent.broker_role.id
        consumer = Person.find(params[:person])
        family = consumer.primary_family
        family.hire_broker_agency(broker_role_id)
        role = 'Broker'
      else
        agent = Person.find(params[:assister])
        role = 'In-Person Assister'
      end
    end
    if role
      status_text = 'Message sent to ' + role + ' ' + agent.full_name + ' <br>'
      if find_email(agent, role)
        agent_assistance_messages(params,agent,role)
      else

        status_text = "Agent has no email.   Please select another"
      end
    else
      status_text = call_customer_service params[:firstname].strip, params[:lastname].strip
    end
    @person = Person.find(params[:person])
    broker_view = render_to_string 'insured/families/_consumer_brokers_widget', :layout => false
    render :plain => {broker: broker_view, status: status_text}.to_json, layout: false
  end

  def family_index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.page page_no
      @total = Family.count
    else
      total_families = Person.search(@q).map(&:families).flatten.uniq
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      format.html { render "insured/families/index" }
      format.js
    end
  end

  def family_index_dt
    @selector = params[:scopes][:selector] if params[:scopes].present?
    @datatable = Effective::Datatables::FamilyDataTable.new(params[:scopes].to_h)
    respond_to do |format|
      format.html { render "/exchanges/hbx_profiles/family_index_datatable" }
    end
  end

  def identity_verification
    @datatable = Effective::Datatables::IdentityVerificationDataTable.new(params[:scopes])
    respond_to do |format|
      format.html { render "/exchanges/hbx_profiles/identity_verification_datatable.html.erb" }
    end
  end

  def user_account_index
    @datatable = Effective::Datatables::UserAccountDatatable.new
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/user_account_index_datatable.html.slim' }
    end
  end

  def outstanding_verification_dt
    @selector = params[:scopes][:selector] if params[:scopes].present?
    @datatable = Effective::Datatables::OutstandingVerificationDataTable.new(params[:scopes])
    respond_to do |format|
      format.html { render "/exchanges/hbx_profiles/outstanding_verification_datatable.html.erb" }
    end
  end

  def hide_form
    @element_to_replace_id = params[:family_actions_id]
  end

  def add_sep_form
    authorize HbxProfile, :can_add_sep?
    getActionParams
    @element_to_replace_id = params[:family_actions_id]
  end

  def show_sep_history
    getActionParams
    @element_to_replace_id = params[:family_actions_id]
  end

  def get_user_info
    # from benefit_sponsors_employer_datatable
    @element_to_replace_id = params[:family_actions_id] || params[:employer_actions_id]
    if params[:person_id].present?
      @person = Person.find(params[:person_id])
    else
      @employer_actions = true
      @people = Person.where(:id => { "$in" => (params[:people_id] || []) })
      @organization = if params.key?(:employer_actions_id)
        BenefitSponsors::Organizations::Profile.find(@element_to_replace_id.split("_").last).organization
      else
        BenefitSponsors::Organizations::Organization.find(@element_to_replace_id.split("_").last)
      end
    end
  end

  def update_effective_date
    @qle = QualifyingLifeEventKind.find(params[:id])
    respond_to do |format|
      format.js {}
    end
    calculate_rule
  end

  def calculate_sep_dates
    calculateDates
    respond_to do |format|
      format.js {}
    end
  end

  def add_new_sep
    @element_to_replace_id = sep_params[:family_actions_id]
    createSep
    respond_to do |format|
      format.js { render :file => "sep/approval/add_sep_result.js.erb", name: @name }
    end
  end

  def cancel_enrollment
    @hbxs = Family.find(params[:family]).all_enrollments.cancel_eligible
    @row = params[:family_actions_id]
    respond_to do |format|
      format.js { render "datatables/cancel_enrollment" }
    end
  end

  def update_cancel_enrollment
    params_parser = ::Forms::BulkActionsForAdmin.new(params.permit!.except(:utf8, :commit, :controller, :action).to_h)
    @result = params_parser.result
    @row = params_parser.row
    @family_id = params_parser.family_id
    params_parser.cancel_enrollments
    respond_to do |format|
      format.js { render :file => "datatables/cancel_enrollment_result.js.erb"}
    end
  end

  def terminate_enrollment
    @hbxs = Family.find(params[:family]).all_enrollments.can_terminate
    @row = params[:family_actions_id]
    respond_to do |format|
      format.js { render "datatables/terminate_enrollment" }
    end

  end

  def update_terminate_enrollment
    params_parser = ::Forms::BulkActionsForAdmin.new(params.permit!.except(:utf8, :commit, :controller, :action).to_h)
    @result = params_parser.result
    @row = params_parser.row
    @family_id = params_parser.family_id
    params_parser.terminate_enrollments
    respond_to do |format|
      format.js { render :file => "datatables/terminate_enrollment_result.js.erb"}
    end
  end

  def view_enrollment_to_update_end_date
    @person = Person.find(params[:person_id])
    @row = params[:family_actions_id]
    @enrollments = @person.primary_family.terminated_enrollments
    @coverage_ended_enrollments = @person.primary_family.hbx_enrollments.where(:aasm_state.in=> ["coverage_terminated", "coverage_termination_pending", "coverage_expired"])
    @dup_enr_ids = fetch_duplicate_enrollment_ids(@coverage_ended_enrollments).map(&:to_s)
  end

  def update_enrollment_termianted_on_date
    begin
      enrollment = HbxEnrollment.find(params[:enrollment_id].strip)
      @row = params[:family_actions_id]
      termination_date = Date.strptime(params["new_termination_date"], "%m/%d/%Y")
      if enrollment.present? && enrollment.reterm_enrollment_with_earlier_date(termination_date, params["edi_required"].present?)
        message = {notice: "Enrollment Updated Successfully."}
      else
        message = {notice: "Unable to find/update Enrollment."}
      end
    rescue Exception => e
      message = {error: e.to_s}
    end
    redirect_to exchanges_hbx_profiles_root_path, flash: message
  end

  def broker_agency_index

    @datatable = Effective::Datatables::BrokerAgencyDatatable.new

    #@q = params.permit(:q)[:q]
    #@broker_agency_profiles = HbxProfile.search_random(@q)


    respond_to do |format|
      format.html { render 'exchanges/hbx_profiles/broker_agency_index_datatable.html.slim' }
    end
  end

  def general_agency_index
    page_string = params.permit(:gas_page)[:gas_page]
    page_no = page_string.blank? ? nil : page_string.to_i

    status_params = params.permit(:status)
    @status = status_params[:status] || 'is_applicant'
    @general_agency_profiles = BenefitSponsors::Organizations::GeneralAgencyProfile.filter_by(@status)
    @general_agency_profiles = Kaminari.paginate_array(@general_agency_profiles).page(page_no)

    respond_to do |format|
      format.html { render "exchanges/hbx_profiles/general_agency_index.html.slim" }
      format.js
    end
  end

  def verification_index
    #@families = Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent").page(params[:page]).per(15)
    # @datatable = Effective::Datatables::DocumentDatatable.new
    @documents = [] # Organization.all_employer_profiles.employer_profiles_with_attestation_document

    respond_to do |format|
      format.html { render partial: "index_verification" }
      format.js {}
    end
  end

  def binder_index
    @organizations = Organization.retrieve_employers_eligible_for_binder_paid

    respond_to do |format|
      format.html { render "employers/employer_profiles/binder_index" }
      format.js {}
    end
  end

  def binder_index_datatable
    dt_query = extract_datatable_parameters
    organizations = []

    all_organizations = Organization.retrieve_employers_eligible_for_binder_paid

    organizations = if dt_query.search_string.blank?
      all_organizations
    else
      org_ids = Organization.search(dt_query.search_string).pluck(:id)
      all_organizations.where({
        "id" => {"$in" => org_ids}
      })
    end

    @draw = dt_query.draw
    @total_records = all_organizations.count
    @records_filtered = organizations.count
    @organizations = organizations.skip(dt_query.skip).limit(dt_query.take)
    render

  end

  def configuration
    @time_keeper = Forms::TimeKeeper.new
    respond_to do |format|
      format.html { render '/exchanges/hbx_profiles/configuration_index.html.erb' }
    end
  end

  def view_terminated_hbx_enrollments
    @person = Person.find(params[:person_id])
    @element_to_replace_id = params[:family_actions_id]
    @enrollments = @person.primary_family.terminated_enrollments
  end

  def reinstate_enrollment
    enrollment = HbxEnrollment.find(params[:enrollment_id].strip)

    if enrollment.present?
      begin
        reinstated_enrollment = enrollment.reinstate(edi: params['edi_required'].present?)
        if reinstated_enrollment.present?
          if params['comments'].present?
            reinstated_enrollment.comments.create(:content => params[:comments].strip, :user => current_user.id)
          end
          message = {notice: "Enrollment Reinstated successfully."}
        end
      rescue Exception => e
        message = {error: e.to_s}
      end
    else
      message = {notice: "Unable to find Enrollment."}
    end

    redirect_to exchanges_hbx_profiles_root_path, flash: message
  end

  def edit_dob_ssn
    authorize Family, :can_update_ssn?
    @person = Person.find(params[:id])
    @element_to_replace_id = params[:family_actions_id]
    respond_to do |format|
      format.js { render "edit_enrollment", person: @person, person_has_active_enrollment: @person_has_active_enrollment}
    end
  end

  def verify_dob_change
    @person = Person.find(params[:person_id])
    @element_to_replace_id = params[:family_actions_id]
    @premium_implications = Person.dob_change_implication_on_active_enrollments(@person, params[:new_dob])
    respond_to do |format|
      format.js { render "edit_enrollment", person: @person, :new_ssn => params[:new_ssn], :new_dob => params[:new_dob],  :family_actions_id => params[:family_actions_id]}
    end
  end

  def update_dob_ssn
    authorize  Family, :can_update_ssn?
    @element_to_replace_id = params[:person][:family_actions_id]
    @person = Person.find(params[:person][:pid]) if !params[:person].blank? && !params[:person][:pid].blank?
    @ssn_match = Person.find_by_ssn(params[:person][:ssn]) unless params[:person][:ssn].blank?
    @ssn_fields = @person.employee_roles.map{|e| e.census_employee.is_no_ssn_allowed?} if @person.active_employee_roles.present?
    @info_changed, @dc_status = sensitive_info_changed?(@person.consumer_role) if @person.consumer_role
    @ssn_require = @ssn_fields.present? && @ssn_fields.include?(false)
    if !@ssn_match.blank? && (@ssn_match.id != @person.id) # If there is a SSN match with another person.
      @dont_allow_change = true
    else
      begin
        @person.dob = Date.strptime(params[:jq_datepicker_ignore_person][:dob], '%m/%d/%Y').to_date
        if params[:person][:ssn].blank?
          if @ssn_require
            @dont_update_ssn = true
          else
            @person.unset(:encrypted_ssn)
          end
        else
          @person.ssn = params[:person][:ssn]
        end
        @person.save!
        @person.consumer_role.check_for_critical_changes(@person.primary_family, info_changed: @info_changed, no_dc_address: "false", dc_status: @dc_status) if @person.consumer_role && @person.is_consumer_role_active?
        CensusEmployee.update_census_employee_records(@person, current_user)
      rescue StandardError => e
        @error_on_save = @person.errors.messages
        @error_on_save[:census_employee] = [e.summary] if @person.errors.messages.blank? && e.present?
      end
    end
    respond_to do |format|
      format.js { render "edit_enrollment", person: @person, :family_actions_id => params[:person][:family_actions_id]  } if @error_on_save
      format.js { render "update_enrollment", person: @person, :family_actions_id => params[:person][:family_actions_id] }
    end
  end

  def new_eligibility
    authorize  HbxProfile, :can_add_pdc?
    @person = Person.find(params[:person_id])
    @element_to_replace_id = params[:family_actions_id]
    respond_to do |format|
      format.js { render "new_eligibility", person: @person, :family_actions_id => params[:family_actions_id]  }
    end
  end

  def create_eligibility
    @element_to_replace_id = params[:person][:family_actions_id]
    family = Person.find(params[:person][:person_id]).primary_family
    family.active_household.create_new_tax_household(params[:person]) rescue nil
  end

  def eligibility_kinds_hash(value)
    if value['pdc_type'] == 'is_medicaid_chip_eligible'
      { is_medicaid_chip_eligible: true, is_ia_eligible: false }.with_indifferent_access
    elsif value['pdc_type'] == 'is_ia_eligible'
      { is_ia_eligible: true, is_medicaid_chip_eligible: false }.with_indifferent_access
    end
  end

  # GET /exchanges/hbx_profiles/1
  # GET /exchanges/hbx_profiles/1.json
  def show
    if current_user.has_csr_role? || current_user.try(:has_assister_role?)
      redirect_to home_exchanges_agents_path
      return
    else
      unless current_user.has_hbx_staff_role?
        redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
        return
      end
    end
    session[:person_id] = nil
    session[:dismiss_announcements] = nil
    @unread_messages = @profile.inbox.unread_messages.try(:count) || 0
  end

  # GET /exchanges/hbx_profiles/new
  def new
    @organization = Organization.new
    @hbx_profile = @organization.build_hbx_profile
  end

  # GET /exchanges/hbx_profiles/1/edit
  def edit
  end

  def inbox
    respond_to do |format|
      format.html { render "exchanges/hbx_profiles/inbox_messages.html.slim" }
    end
  end

# FIXME: I have removed all writes to the HBX Profile models as we
#        don't seem to have functionality that requires them nor
#        permission checks around them.

  # GET /exchanges/hbx_profiles/1/inbox
#  def inbox
#    @inbox_provider = current_user.person.hbx_staff_role.hbx_profile
#    @folder = params[:folder] || 'inbox'
#    @sent_box = true
#  end

  # POST /exchanges/hbx_profiles
  # POST /exchanges/hbx_profiles.json
#  def create
#    @organization = Organization.new(organization_params)
#    @hbx_profile = @organization.build_hbx_profile(hbx_profile_params.except(:organization))

#    respond_to do |format|
#      if @hbx_profile.save
#        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully created.' }
#        format.json { render :show, status: :created, location: @hbx_profile }
#      else
#        format.html { render :new }
#        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
#      end
#    end
#  end

  # PATCH/PUT /exchanges/hbx_profiles/1
  # PATCH/PUT /exchanges/hbx_profiles/1.json
#  def update
#    respond_to do |format|
#      if @hbx_profile.update(hbx_profile_params)
#        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully updated.' }
#        format.json { render :show, status: :ok, location: @hbx_profile }
#      else
#        format.html { render :edit }
#        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
#      end
#    end
#  end

  # DELETE /exchanges/hbx_profiles/1
  # DELETE /exchanges/hbx_profiles/1.json
#  def destroy
#    @hbx_profile.destroy
#    respond_to do |format|
#      format.html { redirect_to exchanges_hbx_profiles_path, notice: 'HBX Profile was successfully destroyed.' }
#      format.json { head :no_content }
#    end
#  end

  def set_date
    authorize HbxProfile, :modify_admin_tabs?
    forms_time_keeper = Forms::TimeKeeper.new(timekeeper_params)
    begin
      forms_time_keeper.set_date_of_record(forms_time_keeper.forms_date_of_record)
      flash[:notice] = "Date of record set to " + TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    rescue Exception=>e
      flash[:error] = "Failed to set date of record, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path
  end

  # Enrollments for APTC / CSR
  def aptc_csr_family_index
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?
    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.all_active_assistance_receiving_for_current_year.page page_no
      @total = Family.all_active_assistance_receiving_for_current_year.count
    else
      person_ids = Person.search(@q).map(&:_id)

      total_families = Family.all_active_assistance_receiving_for_current_year.in("family_members.person_id" => person_ids).entries
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      #format.html { render "insured/families/aptc_csr_listing" }
      format.js {}
    end
  end

  def update_setting
    authorize HbxProfile, :modify_admin_tabs?
    setting_record = Setting.where(name: setting_params[:name]).last

    begin
      setting_record.update(value: setting_params[:value]) if setting_record.present?
    rescue Exception => e
      flash[:error] = "Failed to update setting, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path

  end

  private

  def group_enrollments_by_year_and_market(all_enrollments)
    current_year = TimeKeeper.date_of_record.year
    years = ((current_year - 4)..(current_year + 1))

    years.inject({}) do |hash_map, year|
      ivl_enrs = all_enrollments.select{ |enrollment| !enrollment.is_shop? && enrollment.effective_on.year == year }
      shop_enrs = all_enrollments.select do |enrollment|
        next unless enrollment.present? || enrollment.sponsored_benefit_package.present?

        enrollment.is_shop? && enrollment.sponsored_benefit_package.start_on.year == year
      end
      hash_map["ivl_#{year}"] = ivl_enrs if ivl_enrs.present?
      hash_map["shop_#{year}"] = shop_enrs if shop_enrs.present?
      hash_map
    end
  end

  def get_duplicate_enrs(dup_enrollments)
    product_ids = dup_enrollments.flatten.pluck(:product_id)
    return [] if product_ids.uniq.count == product_ids.count

    product_ids.uniq.inject([]) do |array_of_arrays, product_id|
      current_enr = dup_enrollments.detect{ |en| en.product_id == product_id}
      dup_enrs =  if current_enr.is_shop?
                    dup_enrollments.select do |enr|
                      (enr.subscriber.applicant_id == current_enr.subscriber.applicant_id) &&
                        (enr.market_name == current_enr.market_name) &&
                        (enr.product.id == current_enr.product.id) &&
                        (enr.employer_profile.id == current_enr.employer_profile.id) &&
                        (enr.sponsored_benefit_package.start_on == current_enr.sponsored_benefit_package.start_on)
                    end
                  else
                    dup_enrollments.select do |enr|
                      (enr.subscriber.applicant_id == current_enr.subscriber.applicant_id) &&
                        (enr.market_name == current_enr.market_name) &&
                        (enr.product.id == current_enr.product.id)
                    end
                  end
      array_of_arrays = dup_enrs.to_a if dup_enrs.count > 1
      array_of_arrays
    end
  end

  def fetch_duplicate_enrollment_ids(enrollments)
    enrs_mapping_by_year_and_market = group_enrollments_by_year_and_market(enrollments)
    return [] if enrs_mapping_by_year_and_market.blank?

    enrs_mapping_by_year_and_market.inject([]) do |duplicate_ids, (market_year, enrollments)|
      next duplicate_ids unless enrollments.count > 1
      dups = get_duplicate_enrs(enrollments)
      next duplicate_ids if dups.empty?
      effective_date = dups.map(&:effective_on).max
      dups.each do |enr|
        duplicate_ids << enr.id if enr.effective_on < effective_date
      end
      duplicate_ids
    end
  end

  def permit_params
    params.permit!
  end

  def benefit_application_error_messages(obj)
    obj.errors.full_messages.collect { |error| "<li>#{error}</li>".html_safe }
  end

  def new_ba_params
    params.merge!({ admin_datatable_action: true }).permit(:benefit_sponsorship_id, :admin_datatable_action)
  end

  def create_ba_params
    params.merge!({ pte_count: '0', msp_count: '0', admin_datatable_action: true })
    params.permit(:start_on, :end_on, :fte_count, :pte_count, :msp_count,
                  :open_enrollment_start_on, :open_enrollment_end_on, :benefit_sponsorship_id, :admin_datatable_action, :has_active_ba)
  end

  def sep_params
    params.except(:utf8, :commit).permit(:market_kind, :person, :firstName, :lastName, :family_actions_id,
                                         :effective_on_kind, :qle_id, :event_date, :effective_on_date, :csl_num,
                                         :start_on, :end_on, :next_poss_effective_date, :option1_date, :option2_date, :option3_date, :admin_comment)
  end

  def timekeeper_params
    params.require(:forms_time_keeper).permit(:date_of_record)
  end

  def modify_admin_tabs?
    authorize HbxProfile, :modify_admin_tabs?
  end

  def can_submit_time_travel_request?
    unless authorize HbxProfile, :can_submit_time_travel_request?
      redirect_to root_path, :flash => { :error => "Access not allowed" }
    end
  end

  def view_admin_tabs?
    authorize HbxProfile, :view_admin_tabs?
  end

  def setting_params
    params.require(:setting).permit(:name, :value)
  end

  def agent_assistance_messages(params, agent, role)
    if params[:person].present?
      insured = Person.find(params[:person])
      first_name = insured.first_name
      last_name = insured.last_name
      name = insured.full_name
      insured_email = insured.emails.last.try(:address) || insured.try(:user).try(:email)
      root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + params[:person] +'&original_application_type:'
      body =
        "Please contact #{insured.first_name} #{insured.last_name}. <br> " +
        "Plan shopping help has been requested by #{insured_email}<br>" +
        "<a href='" + root+"phone'>Assist Customer</a>  <br>"
    else
      first_name = params[:first_name]
      last_name = params[:last_name]
      name = first_name.to_s + ' ' + last_name.to_s
      insured_email = params[:email]
      body =  "Please contact #{first_name} #{last_name}. <br>" +
        "Plan shopping help has been requested by #{insured_email}<br>"
    end
    hbx_profile = HbxProfile.find_by_state_abbreviation(aca_state_abbreviation)
    message_params = {
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Agent Mailbox",
      subject: "Please contact #{first_name} #{last_name}. ",
      body: body,
      }
    create_secure_message message_params, hbx_profile, :sent
    create_secure_message message_params, agent, :inbox
    result = UserMailer.new_client_notification(find_email(agent,role), first_name, name, role, insured_email, params[:person].present?)
    result.deliver_now
    puts result.to_s if Rails.env.development?
   end

  def find_hbx_profile
    @profile = current_user.person.try(:hbx_staff_role).try(:hbx_profile)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_hbx_profile
    @hbx_profile = HbxProfile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def organization_params
    params[:hbx_profile][:organization].permit(:organization_attributes)
  end

  def hbx_profile_params
    params[:hbx_profile].permit(:hbx_profile_attributes)
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def view_the_configuration_tab?
    unless authorize HbxProfile, :view_the_configuration_tab?
      redirect_to root_path, :flash => { :error => "Access not allowed" }
    end
  end

  def check_csr_or_hbx_staff
    unless current_user.has_hbx_staff_role? || (current_user.person.csr_role && !current_user.person.csr_role.cac)
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member or a CSR" }
    end
  end

  def authorize_for_instance
    authorize @hbx_profile, "#{action_name}?".to_sym
  end

  def call_customer_service(first_name, last_name)
    "No match found for #{first_name} #{last_name}.  Please call Customer Service at: (855)532-5465 for assistance.<br/>"
  end

  def find_benefit_sponsorship
    @benefit_sponsorship = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id] || params[:id])
    raise "Unable to find benefit sponsorship" if @benefit_sponsorship.blank?
  end

end
