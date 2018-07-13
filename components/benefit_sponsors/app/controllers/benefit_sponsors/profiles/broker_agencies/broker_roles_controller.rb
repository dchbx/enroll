require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerRolesController < ::BenefitSponsors::ApplicationController
        before_action :get_site_key
        before_action :initiate_broker_profile, only: [:create]

        before_action :assign_filter_and_agency_type

        def new_broker
          @broker_candidate = BenefitSponsors::Forms::BrokerCandidate.new
          @organization =  BenefitSponsors::Organizations::Factories::BrokerProfileFactory.new(nil)
          respond_to do |format|
            format.html { render 'new' }
            format.js
          end
        end

        def new_staff_member
          @broker_candidate = BenefitSponsors::Forms::BrokerCandidate.new

          respond_to do |format|
            format.js
          end
        end

        def new_broker_agency
          @broker_agency = BenefitSponsors::Organizations::Factories::BrokerProfileFactory.new(nil)

          respond_to do |format|
            format.html { render 'new' }
            format.js
          end
        end

        def search_broker_agency
          orgs = BenefitSponsors::Organizations::Organization.broker_agency_profiles.or({legal_name: /#{params[:broker_agency_search]}/i}, {"fein" => /#{params[:broker_agency_search]}/i})

          @broker_agency_profiles = orgs.present? ? orgs.map(&:broker_agency_profile) : []
        end

        #TODO: Refactor this after implementing GA & BrokerRole
        def favorite
          @broker_role = BrokerRole.find(params[:id])
          @general_agency_profile = GeneralAgencyProfile.find(params[:general_agency_profile_id])
          if @broker_role.present? && @general_agency_profile.present?
            favorite_general_agencies = @broker_role.search_favorite_general_agencies(@general_agency_profile.id)
            if favorite_general_agencies.present?
              favorite_general_agencies.destroy_all
              @favorite_status = false
            else
              @broker_role.favorite_general_agencies.create(general_agency_profile_id: @general_agency_profile.id)
              @favorite_status = true
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def create
          notice = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
          if params[:person].present?
            @broker_candidate = BenefitSponsors::Forms::BrokerCandidate.new(applicant_params)
            if @broker_candidate.save
              flash[:notice] = notice
              redirect_to broker_registration_profiles_broker_agencies_broker_roles_path
            else
              @filter = params[:person][:broker_applicant_type]
              render 'new'
            end
          else
            if @broker_agency.save
              flash[:notice] = notice
              redirect_to broker_registration_profiles_broker_agencies_broker_roles_path
            else
              @agency_type = 'new'
              render "new"
            end
          end
        end

        private

        def get_site_key
          @site_key = self.class.superclass.current_site.site_key
        end

        def initiate_broker_profile
          return if params[:broker_agency].blank?
          params[:broker_agency].permit!
          @profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new
          #@profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new(market_kind: :aca_shop, entity_kind: params[:broker_agency][:entity_kind].to_sym)
          @broker_agency = BenefitSponsors::Organizations::Factories::BrokerProfileFactory.new(@profile, params[:broker_agency])
        end

        def assign_filter_and_agency_type
          @filter = params[:filter] || 'broker'
          @agency_type = params[:agency_type] || 'new'
        end

        def primary_broker_role_params
          params.require(:organization).permit(
            :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba,
            :fein, :entity_kind, :home_page, :market_kind, :languages_spoken,
            :working_hours, :accept_new_clients,
            :office_locations_attributes => [
              :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
              :phone_attributes => [:kind, :area_code, :number, :extension]
            ]
          )
        end

        def applicant_params
          params.require(:person).permit(:first_name, :last_name, :dob, :email, :npn, :broker_agency_id, :broker_applicant_type,
           :market_kind, {:languages_spoken => []}, :working_hours, :accept_new_clients,
           :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip])
        end
      end
    end
  end
end
