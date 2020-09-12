# frozen_string_literal: true

module FinancialAssistance
  class DeductionsController < ApplicationController
    include ::UIHelpers::WorkflowController
    include NavigationHelper
    include ApplicationHelper

    before_action :find_application_and_applicant
    before_action :load_support_texts, only: [:index]

    def index
      save_faa_bookmark(request.original_url)
      set_admin_bookmark_url
      render layout: 'financial_assistance_nav'
    end

    def new
      @model = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.build
      load_steps
      current_step
      render 'workflow/step', layout: 'financial_assistance_nav'
    end

    def step
      save_faa_bookmark(request.original_url.gsub(%r{/step.*}, "/step/#{@current_step.to_i}"))
      set_admin_bookmark_url
      model_name = @model.class.to_s.split('::').last.downcase
      model_params = params[model_name]
      format_date_params model_params if model_params.present?
      @model.assign_attributes(permit_params(model_params)) if model_params.present?

      if params.key?(model_name)
        @model.workflow = { current_step: @current_step.to_i}
        @current_step = @current_step.next_step if @current_step.next_step.present?
      end

      if params.key?(model_name)
        if @model.save(context: "step_#{@current_step.to_i}".to_sym)
          if params.key? :last_step
            flash[:notice] = "Deduction Added - (#{@model.kind})"
            redirect_to financial_assistance_application_applicant_deductions_path(@application, @applicant)
          else
            render 'workflow/step', layout: 'financial_assistance_nav'
          end
        else
          flash[:error] = build_error_messages(@model)
          render 'workflow/step', layout: 'financial_assistance_nav'
        end
      else
        render 'workflow/step', layout: 'financial_assistance_nav'
      end
    end

    def create
      format_date(params)
      @deduction = @applicant.deductions.build permit_params(params[:deduction])

      if @deduction.save
        render :create
      else
        render head: 'ok'
      end
    end

    def update
      format_date(params)
      @deduction = @applicant.deductions.find params[:id]

      if @deduction.update_attributes permit_params(params[:deduction])
        render :update
      else
        render head: 'ok'
      end
    end

    def destroy
      @deduction = @applicant.deductions.find(params[:id])
      @deduction_kind = @deduction.kind
      @deduction.destroy!

      head :ok
    end

    private

    def format_date(params)
      return if params[:deduction].blank?
      params[:deduction][:start_on] = Date.strptime(params[:deduction][:start_on].to_s, "%m/%d/%Y")
      params[:deduction][:end_on] = Date.strptime(params[:deduction][:end_on].to_s, "%m/%d/%Y") if params[:deduction][:end_on].present?
    end

    # this might not be needed anymore as forms (with dates) have come out of the YAML. Refactor and Replace with the method above.
    def format_date_params(model_params)
      model_params["start_on"] = Date.strptime(model_params["start_on"].to_s, "%m/%d/%Y") if model_params.present?
      model_params["end_on"] = Date.strptime(model_params["end_on"].to_s, "%m/%d/%Y") if model_params.present? && model_params["end_on"].present?
    end

    def build_error_messages(model)
      model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.messages.first[1][0].titleize
    end

    def find_application_and_applicant
      @application = FinancialAssistance::Application.find(params[:application_id])
      @applicant = @application.applicants.find(params[:applicant_id])
    end

    def permit_params(attributes)
      return if attributes.blank?
      attributes.permit!
    end

    def load_support_texts
      file_path = Rails.root.to_s + "/components/financial_assistance/app/views/financial_assistance/shared/support_text.yml"
      raw_support_text = YAML.safe_load(File.read(file_path)).with_indifferent_access
      @support_texts = support_text_placeholders raw_support_text
    end

    def find
      FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id]).deductions.find(params[:id])
    rescue StandardError
      ''
    end
  end
end
