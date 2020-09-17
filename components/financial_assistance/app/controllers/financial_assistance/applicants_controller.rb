# frozen_string_literal: true

module FinancialAssistance
  class ApplicantsController < FinancialAssistance::ApplicationController
    include ::UIHelpers::WorkflowController

    before_action :find, :find_application, :except => [:age_of_applicant] #except the ajax requests
    before_action :load_support_texts, only: [:other_questions, :step, :new, :edit]

    def new
      @applicant = FinancialAssistance::Forms::Applicant.new(:application_id => params.require(:application_id))

      respond_to do |format|
        format.html
        format.js
      end
    end

    def create
      @applicant = FinancialAssistance::Forms::Applicant.new(params.require(:applicant).permit(*applicant_parameters))
      @applicant.application_id = params[:application_id]
      success, _result = @applicant.save

      respond_to do |format|
        if success
          format.js { render js: "window.location = '#{edit_application_path(@application)}'"}
        else
          load_support_texts
          format.js { render 'new' }
        end
      end
    end

    def edit
      %w[home mailing].each{|kind| @applicant.addresses.build(kind: kind) if @applicant.addresses.in(kind: kind).blank?}
      @vlp_doc_subject = @applicant.vlp_subject

      respond_to do |format|
        format.html
        format.js
      end
    end

    def update
      if params[:financial_assistance_applicant].present?
        @applicant.update_attributes!(permit_params(params[:financial_assistance_applicant]))
        head :ok, content_type: "text/html"
      else
        @applicant = FinancialAssistance::Forms::Applicant.new(params.require(:applicant).permit(*applicant_parameters))
        @applicant.application_id = params[:application_id]
        @applicant.applicant_id = params[:id]
        @applicant.save

        redirect_to edit_application_path(@application)
      end
    end

    def other_questions
      save_faa_bookmark(request.original_url)
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
        flash[:error] = build_error_messages_for_other_qns(@applicant)
        redirect_to other_questions_application_applicant_path(@application, @applicant)
      end
    end

    def step
      save_faa_bookmark(request.original_url.gsub(%r{/step.*}, "/step/#{@current_step.to_i}"))
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
      has_spouse =  @application.primary_applicant.relationships.where(kind: 'spouse').present? ? 'true' : 'false'
      render :plain => has_spouse.to_s
    end

    def immigration_document_options
      if params[:target_type] == "FinancialAssistance::Applicant" && params[:target_id].present?
        @target = FinancialAssistance::Applicant.find(params[:target_id])
        # vlp_docs = @target.applicant.vlp_documents
      else
        @target = FinancialAssistance::Forms::Applicant.new
      end

      @vlp_doc_target = params[:vlp_doc_target]
      # vlp_doc_subject = params[:vlp_doc_subject]
      # @country = vlp_docs.detect{|doc| doc.subject == vlp_doc_subject }.try(:country_of_citizenship) if vlp_docs
    end

    private

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
      @application = FinancialAssistance::Application.find_by(id: params[:application_id], family_id: get_current_person.financial_assistance_identifier)
    end

    def find
      # TODO: Not sure about this, added the @model definition because it wasn't defined
      @applicant = find_application.active_applicants.where(id: params[:id]).last || find_application.applicants.last || nil
      @model = @applicant
    end

    def permit_params(attributes)
      attributes.permit!
    end

    def applicant_parameters
      [
        :first_name,
        :last_name,
        :middle_name,
        :name_pfx,
        :name_sfx,
        :dob,
        :ssn,
        :gender,
        :is_applying_coverage,
        :us_citizen,
        :naturalized_citizen,
        :indian_tribe_member,
        :eligible_immigration_status,
        :tribal_id,
        :is_incarcerated,
        :relationship,
        :is_consumer_role,
        :same_with_primary,
        :no_dc_address,
        :is_temporarily_out_of_state,
        :is_homeless,
        :no_ssn,
        :vlp_subject, :citizenship_number, :naturalization_number,
        :alien_number, :passport_number, :sevis_id, :visa_number,
        :receipt_number, :expiration_date, :card_number, :description,
        :i94_number, :country_of_citizenship,
        { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :id, :_destroy] },
        { :phones_attributes => [:kind, :full_phone_number, :id, :_destroy] },
        { :emails_attributes => [:kind, :address, :id, :_destroy],
          :ethnicity => [] }
      ]
    end
  end
end
