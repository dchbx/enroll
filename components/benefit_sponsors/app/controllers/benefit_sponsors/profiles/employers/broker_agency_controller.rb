module BenefitSponsors
  module Profiles
    module Employers
      class BrokerAgencyController < ::BenefitSponsors::ApplicationController
        before_action :find_employer
        before_action :find_broker_agency, :except => [:index, :active_broker]
        before_action :updateable?, only: [:create, :terminate]

        def index
          @filter_criteria = params.permit(:q, :working_hours, :languages => [])

          if @filter_criteria.empty?
            @orgs = BenefitSponsors::Organizations::Organization.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
            @page_alphabets = page_alphabets(@orgs, "legal_name")

            if params[:page].present?
              @page_alphabet = cur_page_no(@page_alphabets.first)
              @organizations = @orgs.where("legal_name" => /^#{@page_alphabet}/i)
            else
              @organizations = @orgs.limit(12).to_a
            end
            @broker_agency_profiles = Kaminari.paginate_array(@organizations.map(&:broker_agency_profile).uniq).page(params[:organization_page] || 1).per(10)
          else
            results = BenefitSponsors::Organizations::Organization.broker_agencies_with_matching_agency_or_broker(@filter_criteria)
            if results.first.is_a?(Person)
              @filtered_broker_roles  = results.map(&:broker_role)
              @broker_agency_profiles = Kaminari.paginate_array(results.map{|broker| broker.broker_role.broker_agency_profile}.uniq).page(params[:organization_page] || 1).per(10)
            else
              @broker_agency_profiles = Kaminari.paginate_array(results.map(&:broker_agency_profile).uniq).page(params[:organization_page] || 1).per(10)
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def show
        end

        def active_broker
          @broker_agency_account = @employer_profile.active_broker_agency_account
        end

        def create
          @broker_management_form = BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm.for_create(params)
          @broker_management_form.save
          flash[:notice] = "Your broker has been notified of your selection and should contact you shortly. You can always call or email them directly. If this is not the broker you want to use, select 'Change Broker'."
          redirect_to profiles_employers_employer_profile_path(@employer_profile, tab: 'brokers')
        rescue => e
          error_msgs = @broker_management_form.errors.map(&:full_messages) if @broker_management_form.errors
          redirect_to(:back, :flash => {error: error_msgs})
        end

        def terminate
          @broker_management_form = BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm.for_terminate(params)

          if @broker_management_form.terminate && @broker_management_form.direct_terminate
            flash[:notice] = "Broker terminated successfully."
            redirect_to profiles_employers_employer_profile_path(@employer_profile, tab: "brokers")
          else
            redirect_to profiles_employers_employer_profile_path(@employer_profile)
          end
        end

        private

        def updateable?
          authorize @employer_profile, :updateable?
        end

        def find_employer
          @employer_profile = find_profile(params["employer_profile_id"])
        end

        def find_broker_agency
          id = params[:id] || params[:broker_agency_id]
          @broker_agency_profile = find_profile(id)
        end

        def find_profile(id)
          BenefitSponsors::Organizations::Profile.find(id)
        end
      end
    end
  end
end
