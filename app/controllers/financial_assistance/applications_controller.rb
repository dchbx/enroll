class FinancialAssistance::ApplicationsController < ApplicationController
  before_action :set_current_person

  include UIHelpers::WorkflowController
  include NavigationHelper
  include Acapi::Notifiers
  require 'securerandom'

  before_filter :load_support_texts, only: [:help_paying_coverage]

  def index
    @family = @person.primary_family
    @applications = @family.applications
  end

  def new
    @application = FinancialAssistance::Application.new
  end

  def create
    @application = @person.primary_family.applications.new
    @application.populate_applicants_for(@person.primary_family)
    @application.save!

    redirect_to edit_financial_assistance_application_path(@application)
  end

  def edit
    save_faa_bookmark(@person, request.original_url)
    @family = @person.primary_family
    @application = @person.primary_family.applications.find params[:id]
    matrix = @family.build_relationship_matrix
    @missing_relationships = @family.find_missing_relationships(matrix)
    render layout: 'financial_assistance'
  end

  def step
    save_faa_bookmark(@person, request.original_url.gsub(/\/step.*/, "/step/#{@current_step.to_i}"))
    flash[:error] = nil
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    @model.clean_conditional_params(model_params) if model_params.present?
    @model.assign_attributes(permit_params(model_params)) if model_params.present?

    if params.key?(model_name)
      if @model.save
        @current_step = @current_step.next_step if @current_step.next_step.present?
        if params[:commit] == "Submit Application"
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          @application.submit! if @application.complete?
          payload = generate_payload(@application)
          if @application.publish(payload)
            # dummy_data_for_demo(params) if @application.complete? && @application.is_submitted? #For_Populating_dummy_ED_for_DEMO #temporary
            redirect_to wait_for_eligibility_response_financial_assistance_application_path(@application)
          else
            @application.unsubmit!
            redirect_to application_publish_error_financial_assistance_application_path(@application)
          end

        else
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          render 'workflow/step', layout: 'financial_assistance'
        end
      else
        @model.assign_attributes(workflow: { current_step: @current_step.to_i })
        @model.save!(validate: false)
        flash[:error] = build_error_messages(@model)
        render 'workflow/step', layout: 'financial_assistance'
      end
    else
      render 'workflow/step', layout: 'financial_assistance'
    end
  end

  def generate_payload application
    render_to_string "events/financial_assistance_application", :formats => ["xml"], :locals => { :financial_assistance_application => application }
  end

  def copy
    if @person.primary_family.application_in_progress.blank?
      old_application = @person.primary_family.applications.find params[:id]
      old_application.active_applicants.each do |applicant|
        applicant.person.person_relationships.each do |pr|
          puts pr.inspect
        end
      end
      @application = old_application.dup
      @application.active_applicants.each do |applicant|
        applicant.person.person_relationships.each do |pr|
          puts pr.inspect
        end
      end
      @application.aasm_state = "draft"
      @application.submitted_at = nil
      @application.created_at = nil
      @application.save!
    end
    redirect_to edit_financial_assistance_application_path(@application)
  end

  def help_paying_coverage
    save_faa_bookmark(@person, request.original_url)
    @transaction_id = params[:id]
  end

  def get_help_paying_coverage_response
    family = @person.primary_family
    family.is_applying_for_assistance = params["is_applying_for_assistance"]
    family.save!
    if family.is_applying_for_assistance
      if family.applications.where(aasm_state: "draft").blank?
        application = family.applications.build(aasm_state: "draft")
        family.active_family_members.each do |family_member|
          application.applicants.build(family_member_id: family_member.id)
        end
        application.save!
      end
      redirect_to application_checklist_financial_assistance_applications_path
    else
      if params["is_applying_for_assistance"].nil?
        flash[:error] = "Please choose an option before you proceed."
        redirect_to help_paying_coverage_financial_assistance_applications_path
      else
        family.applications.where(aasm_state: "draft").destroy_all
        redirect_to insured_family_members_path(consumer_role_id: @person.consumer_role.id)
      end
    end
  end

  def application_checklist
    save_faa_bookmark(@person, request.original_url)
    @application = @person.primary_family.application_in_progress
  end

  def review_and_submit
    save_faa_bookmark(@person, request.original_url)
    @consumer_role = @person.consumer_role
    @application = @person.primary_family.application_in_progress
    @applicants = @application.active_applicants

    render layout: 'financial_assistance'
  end

  def wait_for_eligibility_response
    save_faa_bookmark(@person, financial_assistance_applications_path)
    @family = @person.primary_family
    @application = @person.primary_family.applications.find(params[:id])
  end

  def eligibility_results
    save_faa_bookmark(@person, request.original_url)
    @family = @person.primary_family
    @application = @person.primary_family.applications.find(params[:id])

    render layout: 'financial_assistance' if params.keys.include?"cur"
  end

  def application_publish_error
    save_faa_bookmark(@person, request.original_url)
    @family = @person.primary_family
    @application = @person.primary_family.applications.find(params[:id])

    render layout: 'financial_assistance'
  end

  def eligibility_response_error
    save_faa_bookmark(@person, request.original_url)
    @family = @person.primary_family
    @application = @person.primary_family.applications.find(params[:id])
    @application.update_attributes(determination_http_status_code: 504) if @application.determination_http_status_code.nil?
    @application.send_failed_response

    render layout: 'financial_assistance'
  end

  def check_eligibility_results_received
    application = @person.primary_family.applications.find(params[:id])
    render :text => "#{application.success_status_codes?(application.determination_http_status_code)}"
  end

  private

  def dummy_data_for_demo(params)
    #Dummy_ED
    @model.update_attributes!(aasm_state: "determined", assistance_year: TimeKeeper.date_of_record.year)
    @model.active_applicants.each do |applicant|
      applicant.update_attributes!(is_ia_eligible: true)
    end
    @model.tax_households.each do |txh|
      txh.update_attributes!(allocated_aptc: 200.00)
      @model.eligibility_determinations.build(max_aptc: 200.00,
                                              csr_percent_as_integer: 73,
                                              csr_eligibility_kind: "csr_73",
                                              determined_on: TimeKeeper.datetime_of_record - 30.days,
                                              determined_at: TimeKeeper.datetime_of_record - 30.days,
                                              premium_credit_strategy_kind: "allocated_lump_sum_credit",
                                              e_pdc_id: "3110344",
                                              source: "Haven",
                                              tax_household_id: txh.id).save!
      @model.active_applicants.second.update_attributes!(is_medicaid_chip_eligible: true, is_ia_eligible: false) if txh.active_applicants.count > 1
    end
  end

  def build_error_messages(model)
    model.valid? ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
  end

  def hash_to_param param_hash
    ActionController::Parameters.new(param_hash)
  end

  def load_support_texts
   @support_texts = YAML.load_file("app/views/financial_assistance/shared/support_text.yml")
  end

  def permit_params(attributes)
    attributes.permit!
  end

  def find
    @application = @person.primary_family.applications.find(params[:id]) if params.key?(:id)
  end
end
