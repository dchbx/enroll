module Insured
  class InteractiveIdentityVerificationsController < ApplicationController
    include NavigationHelper
    before_action :set_current_person

    def new
      service = ::IdentityVerification::InteractiveVerificationService.new
      service_response = service.initiate_session(render_session_start)
      respond_to do |format|
        format.html do
          if service_response.blank?
            redirect_to :action => "service_unavailable"
          else
            if service_response.failed?
              @step = 'start'
              @verification_response= service_response
              redirect_to :action => "failed_validation", :step => @step, :verification_transaction_id => @verification_response.transaction_id
            else
              @interactive_verification = service_response.to_model
              render :new
            end
          end
        end
      end
    end

    def service_unavailable
      session[:person_id] = params["person_id"] if params.keys.include?("person_id")
      set_consumer_bookmark_url
      @person.consumer_role.move_identity_documents_to_outstanding
      render "service_unavailable"
    end

    def failed_validation
      set_consumer_bookmark_url
      @step = params[:step]
      @verification_transaction_id = params[:verification_transaction_id]
      @person.consumer_role.move_identity_documents_to_outstanding
      render "failed_validation"
    end

    def create
      @interactive_verification = ::IdentityVerification::InteractiveVerification.new(params.require(:interactive_verification).permit!)
      respond_to do |format|
        format.html do
          if @interactive_verification.valid?
            service = ::IdentityVerification::InteractiveVerificationService.new
            service_response = service.respond_to_questions(render_question_responses(@interactive_verification))
            if service_response.blank?
              redirect_to :action => "service_unavailable"
            else
              if service_response.successful?
                process_successful_interactive_verification(service_response)
              else
                @step = 'questions'
                @verification_response= service_response
                redirect_to :action => "failed_validation", :step => @step, :verification_transaction_id => @verification_response.transaction_id
              end
            end
          else
            render "new"
          end
        end
      end
    end

    def update
      @transaction_id = params.require(:id)

      respond_to do |format|
        format.html do
            service = ::IdentityVerification::InteractiveVerificationService.new
            service_response = service.check_override(render_verification_override(@transaction_id))
            if service_response.blank?
              redirect_to :action => "service_unavailable"
            else
              if service_response.successful?
                process_successful_interactive_verification(service_response)
              else
                @verification_response = service_response
                redirect_to :action =>  "failed_validation", :verification_transaction_id => @verification_response.transaction_id
              end
            end
        end
      end
    end

    def process_successful_interactive_verification(service_response)
      consumer_role = @person.consumer_role
      consumer_user = @person.user
      session[:person_id] = @person.id
      #TODO TREY KEVIN JIM There is no user when CSR creates enroooment
      if consumer_user
        consumer_user.identity_final_decision_code = User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        consumer_user.identity_response_code = User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        consumer_user.identity_response_description_text = service_response.response_text
        consumer_user.identity_final_decision_transaction_id = service_response.transaction_id
        consumer_user.identity_verified_date = TimeKeeper.date_of_record
        consumer_user.save!
      end
      consumer_role.move_identity_documents_to_verified
      redirect_to consumer_role.admin_bookmark_url.present? ? consumer_role.admin_bookmark_url : help_paying_coverage_financial_assistance_applications_path
    end

    def render_session_start
      render_to_string "events/identity_verification/interactive_session_start", :formats => ["xml"], :locals => { :individual => @person }
    end

    def render_question_responses(session)
      render_to_string "events/identity_verification/interactive_questions_response", :formats => ["xml"], :locals => { :session => session }
    end

    def render_verification_override(transaction_id)
      render_to_string "events/identity_verification/interactive_verification_override", :formats => ["xml"], :locals => { :transaction_id => transaction_id }
    end

  end
end
