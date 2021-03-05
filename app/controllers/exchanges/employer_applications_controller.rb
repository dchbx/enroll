# frozen_string_literal: true

module Exchanges
  class EmployerApplicationsController < ApplicationController
    include Pundit
    include Config::AcaHelper
    include ::L10nHelper

    before_action :can_modify_plan_year?, only: [:terminate, :cancel, :reinstate]
    before_action :check_hbx_staff_role, except: :term_reasons
    before_action :find_benefit_sponsorship, except: :term_reasons

    def index
      @allow_mid_month_voluntary_terms = allow_mid_month_voluntary_terms?
      @allow_mid_month_non_payment_terms = allow_mid_month_non_payment_terms?
      @show_termination_reasons = show_termination_reasons?
      @element_to_replace_id = params[:employers_action_id]
    end

    def terminate
      @application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
      end_on = Date.strptime(params[:end_on], "%m/%d/%Y")
      termination_kind = params['term_kind']
      termination_reason = params['term_reason']
      transmit_to_carrier = params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true ? true : false
      @service = BenefitSponsors::Services::BenefitApplicationActionService.new(@application, { end_on: end_on, termination_kind: termination_kind, termination_reason: termination_reason, transmit_to_carrier: transmit_to_carrier })
      result, _application, errors = @service.terminate_application
      if errors.present?
        flash[:error] = "#{@benefit_sponsorship.organization.legal_name}'s Application could not be terminated: #{errors.values.to_sentence}"
      else
        flash[:notice] = "#{@benefit_sponsorship.organization.legal_name}'s Application terminated successfully."
      end
      render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
    end

    def cancel
      @application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
      transmit_to_carrier = params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true ? true : false
      @service = BenefitSponsors::Services::BenefitApplicationActionService.new(@application, { transmit_to_carrier: transmit_to_carrier })
      result, _application, errors = @service.cancel_application
      if errors.present?
        flash[:error] = "#{@benefit_sponsorship.organization.legal_name}'s Application could not be canceled due to #{errors.inject(''){|memo, error| '#{memo}<li>#{error}</li>'}.html_safe}"
      else
        flash[:notice] = "#{@benefit_sponsorship.organization.legal_name}'s Application canceled successfully."
      end
      render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
    end

    def term_reasons
      @reasons =
        if params[:reason_type_id] == "term_actions_nonpayment"
          BenefitSponsors::BenefitApplications::BenefitApplication::NON_PAYMENT_TERM_REASONS
        else
          BenefitSponsors::BenefitApplications::BenefitApplication::VOLUNTARY_TERM_REASONS
        end
      render json: @reasons
    end

    def reinstate
      application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
      transmit_to_carrier = params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true ? true : false
      result = EnrollRegistry[:benefit_application_reinstate]{ {params: {benefit_application: application, options: {transmit_to_carrier: transmit_to_carrier} } } }
      if result.success?
        flash[:notice] = "#{application.benefit_sponsorship.legal_name} - #{l10n('exchange.employer_applications.success_message')} #{(application.canceled? ? application.start_on : application.end_on.next_day).to_date}"
      else
        flash[:error] = "#{application.benefit_sponsorship.legal_name} - #{result.failure}"
      end
      redirect_to exchanges_hbx_profiles_root_path
    rescue StandardError => e
      Rails.logger.error { "#{application.benefit_sponsorship.legal_name} - #{l10n('exchange.employer_applications.unable_to_reinstate')} - #{e.backtrace}" }
      redirect_to exchanges_hbx_profiles_root_path, :flash[:error] => "#{application.benefit_sponsorship.legal_name} - #{l10n('exchange.employer_applications.unable_to_reinstate')}"
    end

    private

    def can_modify_plan_year?
      authorize HbxProfile, :can_modify_plan_year?
    end

    def check_hbx_staff_role
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
    end

    def find_benefit_sponsorship
      @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:employer_id])
    end
  end
end
