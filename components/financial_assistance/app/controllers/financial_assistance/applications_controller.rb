# frozen_string_literal: true

module FinancialAssistance
  class ApplicationsController < ApplicationController

    before_action :set_current_person
    before_action :set_primary_family

    before_action :check_eligibility, only: [:create, :get_help_paying_coverage_response, :copy]
    before_action :init_cfl_service, only: :review_and_submit
    before_action :family_relationships, only: :review_and_submit

    include ::UIHelpers::WorkflowController
    include Acapi::Notifiers
    require 'securerandom'

    def index
      @family = @person.primary_family
      @family_members = @person.primary_family.active_family_members
      @applications = @family.applications
      @employee_role = @person.active_employee_roles.first if @person.active_employee_roles.present?
    end

    def new
      @application = FinancialAssistance::Application.new
    end

    def create
      @application = @family.applications.new
      @application.populate_applicants_for(@family)
      @application.save!

      redirect_to edit_application_path(@application)
    end

    def edit
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @family = @person.primary_family
      @application = @person.primary_family.applications.find(params[:id])
      load_support_texts
      matrix = @family.build_relationship_matrix
      @missing_relationships = @family.find_missing_relationships(matrix)
      render layout: 'financial_assistance_nav'
    end

    def step # rubocop:disable Metrics/CyclomaticComplexity
      save_faa_bookmark(@person, request.original_url.gsub(%r{/step.*}, "/step/#{@current_step.to_i}"))
      set_admin_bookmark_url
      flash[:error] = nil
      model_name = @model.class.to_s.split('::').last.downcase
      model_params = params[model_name]
      @model.clean_conditional_params(model_params) if model_params.present?
      @model.assign_attributes(permit_params(model_params)) if model_params.present?

      # rubocop:disable Metrics/BlockNesting
      if params.key?(model_name)
        if @model.save
          @current_step = @current_step.next_step if @current_step.next_step.present?
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          if params[:commit] == "Submit Application"
            dummy_data_5_year_bar(@application)
            @application.submit! if @application.complete?
            payload = generate_payload(@application)
            if @application.publish(payload)
              #dummy_data_for_demo(params) if @application.complete? && @application.is_submitted? #For_Populating_dummy_ED_for_DEMO #temporary
              redirect_to wait_for_eligibility_response_application_path(@application)
            else
              @application.unsubmit!
              redirect_to application_publish_error_application_path(@application)
            end

          else
            render 'workflow/step', layout: 'financial_assistance_nav'
          end
        else
          @model.assign_attributes(workflow: { current_step: @current_step.to_i })
          @model.save!(validate: false)
          flash[:error] = build_error_messages(@model)
          render 'workflow/step', layout: 'financial_assistance_nav'
        end
      else
        render 'workflow/step', layout: 'financial_assistance_nav'
      end
      # rubocop:enable Metrics/BlockNesting
    end

    def generate_payload(_application)
      ::FinancialAssistance::ApplicationController.new.render_to_string(
        "financial_assistance/events/financial_assistance_application",
        :formats => ["xml"],
        :locals => { :financial_assistance_application => @application }
      )
    end

    def copy
      service = application_service.new(@family, {application_id: params[:id]})
      @application = service.process_application if service.code == :copy!
      redirect_to edit_application_path(@application)
    end

    def help_paying_coverage
      @application = @person.primary_family.applications.find(params[:id]) if params[:id]
      load_support_texts
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @transaction_id = params[:id]
    end

    def render_message
      @message = params["message"]
    end

    def get_help_paying_coverage_response # rubocop:disable Naming/AccessorMethodName
      if params["is_applying_for_assistance"].blank?
        flash[:error] = "Please choose an option before you proceed."
        redirect_to help_paying_coverage_applications_path
      elsif params["is_applying_for_assistance"] == "true"
        @family.is_applying_for_assistance = @assistance_status
        @family.save!
        @assistance_status ? aqhp_flow : redirect_to_msg
      else
        uqhp_flow
      end
    end

    def uqhp_flow
      @family.applications.where(aasm_state: "draft").destroy_all
      redirect_to main_app.insured_family_members_path(consumer_role_id: @person.consumer_role.id)
    end

    def redirect_to_msg
      redirect_to render_message_applications_path(message: @message)
    end

    def application_checklist
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @application = @person.primary_family.application_in_progress
    end

    def review_and_submit
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @consumer_role = @person.consumer_role
      @application = @person.primary_family.application_in_progress
      @applicants = @application.active_applicants if @application.present?
      if @application.blank?
        redirect_to applications_path
      else
        render layout: 'financial_assistance_nav'
      end
    end

    def review
      save_faa_bookmark(@person, request.original_url)
      @application = FinancialAssistance::Application.where(id: params["id"]).first
      @applicants = @application.active_applicants if @application.present?
      redirect_to applications_path if @application.blank?
    end

    def wait_for_eligibility_response
      save_faa_bookmark(@person, applications_path)
      set_admin_bookmark_url
      @family = @person.primary_family
      @application = @person.primary_family.applications.find(params[:id])
    end

    def eligibility_results
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @family = @person.primary_family
      @application = @person.primary_family.applications.find(params[:id])

      render layout: 'financial_assistance_nav' if params.keys.include? "cur"
    end

    def application_publish_error
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @family = @person.primary_family
      @application = @person.primary_family.applications.find(params[:id])

      render layout: 'financial_assistance_nav'
    end

    def eligibility_response_error
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @family = @person.primary_family
      @application = @person.primary_family.applications.find(params[:id])
      @application.update_attributes(determination_http_status_code: 999) if @application.determination_http_status_code.nil?
      @application.send_failed_response

      render layout: 'financial_assistance_nav'
    end

    def check_eligibility_results_received
      application = @person.primary_family.applications.find(params[:id])
      render :plain => application.success_status_codes?(application.determination_http_status_code).to_s
    end

    def checklist_pdf
      send_file(Rails.root.join("public", "ivl_checklist.pdf").to_s, :disposition => "inline", :type => "application/pdf")
    end

    private

    def init_cfl_service
      @cfl_service = ::FinancialAssistance::Services::ConditionalFieldsLookupService.new
    end

    def family_relationships
      matrix = @family.build_relationship_matrix
      @all_relationships = @family.find_all_relationships(matrix)
    end

    def check_eligibility
      call_service
      return if params['action'] == "get_help_paying_coverage_response"
      [(flash[:error] = helpers.l10n(helpers.decode_msg(@message))), (redirect_to applications_path)] unless @assistance_status
    end

    def call_service
      if EnrollRegistry[:faa_ext_service].setting(:aceds_curam).item
        person = FinancialAssistance::Factories::AssistanceFactory.new(@person)
        @assistance_status, @message = person.search_existing_assistance
      else
        @assistance_status = true
        @message = nil
      end
    end

    def set_primary_family
      @family = @person.primary_family
    end

    def aqhp_flow
      if @family.applications.where(aasm_state: "draft").blank?
        application = @family.applications.build(aasm_state: "draft")
        @family.active_family_members.each do |family_member|
          application.applicants.build(family_member_id: family_member.id)
        end
        application.save!
      end
      redirect_to application_checklist_applications_path
    end

    # TODO: Remove dummy data before prod
    def dummy_data_for_demo(_params)
      #Dummy_ED
      coverage_year = @person.primary_family.application_applicable_year
      @model.update_attributes!(aasm_state: "determined", assistance_year: coverage_year, determination_http_status_code: 200)

      @model.tax_households.each do |txh|
        txh.update_attributes!(allocated_aptc: 200.00, is_eligibility_determined: true, effective_starting_on: Date.new(coverage_year, 0o1, 0o1))
        txh.eligibility_determinations.build(max_aptc: 200.00,
                                             csr_percent_as_integer: 73,
                                             csr_eligibility_kind: "csr_73",
                                             determined_on: TimeKeeper.datetime_of_record - 30.days,
                                             determined_at: TimeKeeper.datetime_of_record - 30.days,
                                             premium_credit_strategy_kind: "allocated_lump_sum_credit",
                                             e_pdc_id: "3110344",
                                             source: "Haven").save!
        txh.applicants.first.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: false, is_without_assistance: true) if txh.applicants.count > 0
        txh.applicants.second.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: true, is_without_assistance: false) if txh.applicants.count > 1
        txh.applicants.third.update_attributes!(is_medicaid_chip_eligible: true, is_ia_eligible: false, is_without_assistance: false) if txh.applicants.count > 2

        #Update the Income and MEC verifications to Outstanding
        @model.applicants.each do |applicant|
          applicant.update_attributes!(:assisted_income_validation => "outstanding", :assisted_mec_validation => "outstanding", aasm_state: "verification_outstanding")
          applicant.verification_types.each { |verification| verification.update_attributes!(validation_status: "outstanding") }
        end
      end
    end

    # TODO: Remove dummy stuff before prod
    def dummy_data_5_year_bar(application)
      return unless application.primary_applicant.present? && ["bar5"].include?(application.family.primary_applicant.person.last_name.downcase)
      application.active_applicants.each { |applicant| applicant.update_attributes!(is_subject_to_five_year_bar: true, is_five_year_bar_met: false)}
    end

    def build_error_messages(model)
      model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
    end

    def hash_to_param(param_hash)
      ActionController::Parameters.new(param_hash)
    end

    def load_support_texts
      file_path = lookup_context.find_template("financial_assistance/shared/support_text.yml").identifier
      raw_support_text = YAML.safe_load(File.read(file_path)).with_indifferent_access
      @support_texts = helpers.support_text_placeholders raw_support_text
    end

    def permit_params(attributes)
      attributes.permit!
    end

    def find
      @application = @person.primary_family.applications.find(params[:id]) if params.key?(:id)
    end

    def application_service
      FinancialAssistance::Services::ApplicationService
    end
  end
end
