require_relative '../../../../lib/api/v1/mobile_api_helper'

module Api
  module V1
    class MobileApiController < ApplicationController
      include MobileApiHelper
      include MobileApiRosterHelper

      before_filter :employer_profile, except: :employers_list

      def employers_list
        execute {
          json = employers_and_broker_agency current_user, params[:id]
          if json
            render json: json
          else
            render json: {error: 'no broker agency profile found'}, :status => :not_found
          end
        }
      end

      def employer_details
        execute {
          if @employer_profile
            render json: marshall_employer_details_json(@employer_profile, params[:report_date])
          else
            render json: {file: 'public/404.html'}, status: :not_found
          end
        }
      end

      def employee_roster
        execute {
          census_employees = employees_by @employer_profile, params[:employee_name], params[:status]
          limited_census_employees = census_employees.limit(50).to_a #TODO: smaller limits, & paging past 50

          render json: {
              employer_name: @employer_profile.legal_name,
              total_num_employees: census_employees.size,
              roster: render_roster_employees(limited_census_employees, @employer_profile.renewing_published_plan_year.present?)
          }
        }
      end

      #
      # Private
      #
      private

      def execute
        begin
          yield
        rescue Exception => e
          logger.error "Exception caught in employer_details: #{e.message}"
          e.backtrace.each { |line| logger.error line }
          render json: {error: e.message}, :status => :internal_server_error
        end
      end

      def employer_profile
        @employer_profile ||= EmployerProfile.find params[:id] || params[:employer_profile_id]
      end

    end
  end
end