require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    class RegistrationsController < ::BenefitSponsors::ApplicationController
      include BenefitSponsors::Concerns::ProfileRegistration
      include Pundit

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      layout :resolve_layout

      def new
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: profile_type, portal: params[:portal])
        authorize @agency
        authorize @agency, :redirect_home?
        set_ie_flash_by_announcement unless is_employer_profile?
        respond_to do |format|
          format.html
          format.js
        end
      end

      def create
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_create(registration_params)
        authorize @agency
        begin
          saved, result_url = @agency.save
          result_url = self.send(result_url)
          if saved
            if is_employer_profile?
              person = current_person
              create_sso_account(current_user, current_person, 15, "employer") do
              end
              flash[:notice] = "Your employer account has been setup successfully." if params[:manage_portals]
            elsif is_general_agency_profile? || dc_broker_profile?
              flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
            end
            redirect_to result_url unless dc_broker_profile?
            render 'confirmation', :layout => 'single_column' if dc_broker_profile?
            return
          end
        rescue Exception => e
          flash[:error] = e.message
        end
        params[:profile_type] = profile_type
        flash[:error] = @agency.errors.full_messages if flash[:error].blank?
        render default_template, layout: layout_on_render
      end

      def edit
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_edit(profile_id: params[:id])
        authorize @agency

        render layout: 'single_column' if @agency.organization.is_broker_profile? || @agency.organization.is_general_agency_profile?
      end

      def update
        @agency = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_update(registration_params)
        authorize @agency
        updated, result_url = @agency.update
        result_url = self.send(result_url)
        if updated
          flash[:notice] = 'Employer successfully Updated.' if is_employer_profile?
          flash[:notice] = 'Broker Agency Profile successfully Updated.' if is_broker_profile?
          flash[:notice] = 'General Agency Profile successfully Updated.' if is_general_agency_profile?
        else
          org_error_msg = @agency.errors.full_messages.join(",").humanize if @agency.errors.present?

          flash[:error] = "Employer information not saved. #{org_error_msg}."
        end
        redirect_to result_url
      end

      def counties_for_zip_code
        @counties = BenefitMarkets::Locations::CountyZip.where(zip: params[:zip_code]).pluck(:county_name).uniq

        render json: @counties
      end

      private

      def profile_type
        @profile_type = params[:profile_type] || params[:agency][:profile_type] || @agency.profile_type
      end

      def resolve_layout
        case action_name
        when "new_employer_profile_form"
          "bootstrap_4_two_column"
        when "edit"
          "two_column"
        end
      end

      def layout_on_render
        return 'bootstrap_4_two_column' if params[:manage_portals]
        'two_column'
      end

      def default_template
        return :new_employer_profile_form if params[:manage_portals]
        :new
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_general_profile?
        profile_type == "general_agency"
      end

      def is_general_agency_profile?
        profile_type == "general_agency"
      end

      def registration_params
        current_user_id = Person.find(params[:person_id]).user&.id if params[:manage_portals] && params[:person_id]
        current_user_id ||= current_user.present? ? current_user.id : nil
        params[:agency] ||= {}
        agency_params = params.permit(agency: {})
        agency_params[:agency].merge!({:profile_id => params["id"], :current_user_id => current_user_id, :person_id => params["person_id"]})
      end

      def organization_params
        org_params = params.require(:agency).require(:organization).permit(
          :legal_name, :dba, :fein, :entity_kind, :sic_code,
          :profile_attributes => {
            :office_locations_attributes => [
              {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county]},
              {:phone_attributes => [:kind, :area_code, :number, :extension]},
              {:email_attributes => [:kind, :address]},
              :is_primary
            ]
          }
        )

        org_params[:profile_attributes][:office_locations_attributes].delete_if {|_key, value| value.blank?} if org_params[:profile_attributes][:office_locations_attributes].present?

        org_params
      end

      def current_person
        current_user.reload # devise current user not loading changes
        current_user.person
      end

      def is_site_dc?
        Settings.site.key == :dc
      end

      def dc_broker_profile?
        is_broker_profile? && is_site_dc?
      end

      def user_not_authorized(exception)
        action = exception.query.to_sym

        case action
        when :redirect_home?
          if current_user
            redirect_to self.send(:agency_home_url, exception.record.profile_id)
          else
            session[:custom_url] = main_app.new_user_session_path
            super
          end
        when :new?
          params_hash = params.permit(:profile_type, :controller, :action)
          session[:portal] = url_for(params_hash)
          redirect_to self.send(:sign_up_url)
        else
          session[:custom_url] = main_app.new_user_registration_path unless current_user
          super
        end
      end
    end
  end
end
