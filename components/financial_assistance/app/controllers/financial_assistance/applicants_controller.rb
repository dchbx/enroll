# frozen_string_literal: true

module FinancialAssistance
  class ApplicantsController < ::ApplicationController
    include ::UIHelpers::WorkflowController

    before_action :set_current_person
    before_action :find, :find_application, :except => [:age_of_applicant, :primary_applicant_has_spouse] #except the ajax requests
    before_action :load_support_texts, only: [:other_questions, :step]

    def edit
      @applicant = find
      render html: '', layout: 'financial_assistance_nav'
    end

    def other_questions
      save_faa_bookmark(@person, request.original_url)
      set_admin_bookmark_url
      @applicant = @application.active_applicants.find(params[:id])
      render layout: 'financial_assistance_nav'
    end

    def save_questions
      format_date_params params[:applicant] if params[:applicant].present?
      @applicant = @application.active_applicants.find(params[:id])
      @applicant.assign_attributes(permit_params(params[:applicant])) if params[:applicant].present?
      if @applicant.save(context: :other_qns)
        redirect_to edit_application_path(@application)
      else
        @applicant.save(validate: false)
        @applicant.valid?(:other_qns)
        flash[:error] = build_error_messages_for_other_qns(@applicant)
        redirect_to other_questions_application_applicant_path(@application, @applicant)
      end
    end

    def step
      save_faa_bookmark(@person, request.original_url.gsub(%r{/step.*}, "/step/#{@current_step.to_i}"))
      set_admin_bookmark_url
      flash[:error] = nil
      model_name = @model.class.to_s.split('::').last.downcase
      model_params = params[model_name]
      @model.clean_conditional_params(model_params) if model_params.present?
      @model.assign_attributes(permit_params(model_params)) if model_params.present?
      if params.key?(model_name)
        if @model.save(context: "step_#{@current_step.to_i}".to_sym)
          @applicant.reload
          @application.reload
          @current_step = @current_step.next_step if @current_step.next_step.present?
          if params.key? :last_step
            @model.update_attributes!(workflow: { current_step: 1 })
            redirect_to application_applicant_incomes_path(@application, @applicant)
          else
            @model.update_attributes!(workflow: { current_step: @current_step.to_i })
            render 'workflow/step', layout: 'financial_assistance_nav'
          end
        else
          # page.current_path
          @model.assign_attributes(workflow: { current_step: @current_step.to_i })
          @model.save!(validate: false)
          flash[:error] = build_error_messages(@model)
          render 'workflow/step', layout: 'financial_assistance_nav'
        end
      else
        render 'workflow/step', layout: 'financial_assistance_nav'
      end
    end

    def age_of_applicant
      applicant = FinancialAssistance::Application.find(params[:application_id]).active_applicants.find(params[:applicant_id])
      render :plain => applicant.age_of_the_applicant.to_s
    end

    def primary_applicant_has_spouse
      has_spouse =  @person.person_relationships.where(kind: 'spouse').first.present? ? 'true' : 'false'
      render :plain => has_spouse.to_s
    end

    def update
      @applicant.update_attributes!(permit_params(params[:financial_assistance_applicant]))
      head :ok, content_type: "text/html"
    end

    private

    def load_support_texts
      file_path = lookup_context.find_template("financial_assistance/shared/support_text.yml").identifier
      raw_support_text = YAML.safe_load(File.read(file_path)).with_indifferent_access
      @support_texts = helpers.support_text_placeholders raw_support_text
    end

    def format_date_params(model_params)
      model_params["pregnancy_due_on"] = Date.strptime(model_params["pregnancy_due_on"].to_s, "%m/%d/%Y") if model_params["pregnancy_due_on"].present?
      model_params["pregnancy_end_on"] = Date.strptime(model_params["pregnancy_end_on"].to_s, "%m/%d/%Y") if model_params["pregnancy_end_on"].present?
      model_params["student_status_end_on"] = Date.strptime(model_params["student_status_end_on"].to_s, "%m/%d/%Y") if model_params["student_status_end_on"].present?
    end

    def build_error_messages(model)
      model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.messages.first[1][0].titleize
    end

    def build_error_messages_for_other_qns(model)
      model.valid?(:other_qns) ? nil : model.errors.messages.first[1][0].titleize
    end

    def find_application
      @application = FinancialAssistance::Application.find(params[:application_id])
    end

    def find
      # TODO: Not sure about this, added the @model definition because it wasn't defined
      @applicant = find_application.active_applicants.where(id: params[:id]).last || find_application.applicants.last || nil
      @model = @applicant
    end

    def permit_params(attributes)
      attributes.permit!
    end
  end
end
