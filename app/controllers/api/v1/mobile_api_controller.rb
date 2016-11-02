module Api
  module V1
    class MobileApiController < ApplicationController
    
      include MobileApiHelper
      include MobileApiRosterHelper

      def employers_list
        employer_profiles, broker_agency_profile, broker_name = fetch_employers_and_broker_agency(current_user, params[:id])
        if broker_agency_profile
          @employer_details =
                marshall_employer_summaries_json(employer_profiles, params[:report_date])
          render json: {
                 broker_name: broker_name,
                 broker_agency:  broker_agency_profile.legal_name,
                 broker_agency_id:  broker_agency_profile.id,
                 broker_clients: @employer_details 
          } 
        else
          render json: { error: 'no broker agency profile found' }, :status => :not_found
        end
      rescue Exception => e 
          logger.error "Exception caught in employer_details: #{e.message}"
          e.backtrace.each { |line| logger.error line }
          render json: { error: e.message }, :status => :internal_server_error
      end

      def employer_details
        employer_profile = fetch_employer_profile
        if employer_profile.blank?
          render json: { file: 'public/404.html'}, status: :not_found 
        else
          render json: marshall_employer_details_json(employer_profile, params[:report_date])
        end
      rescue Exception => e 
          logger.error "Exception caught in employer_details: #{e.message}"
          e.backtrace.each { |line| logger.error line }
          render json: { error: e.message }, :status => :internal_server_error
      end

      def fetch_employer_profile
        # check that the current user is:
        # - the employer indicated by the id
        # - their broker
        # - staff at their broker's broker agency
        # - or HBX staff
        id_params = params.permit(:id, :employer_profile_id, :report_date)
        id = id_params[:id] || id_params[:employer_profile_id]  #TODO user check
        EmployerProfile.find(id)
      end

      def employee_roster
        employer_profile = fetch_employer_profile
        has_renewal = employer_profile.renewing_published_plan_year.present? 
        census_employees = employees_by(employer_profile, params[:employee_name], params[:status])  
        total_num_employees = census_employees.count
        census_employees = census_employees.limit(50).to_a #TODO: smaller limits, & paging past 50

        render json: { 
          employer_name: employer_profile.legal_name,
          total_num_employees: total_num_employees,
          roster: render_roster_employees(census_employees, has_renewal)
        }
      end

    end
  end
end