require_relative '../../../../lib/api/v1/employer_helper'

module Api
  module V1
    class MobileApiController < ApplicationController
      before_filter :employer_profile, except: :employers_list

      def employers_list
        execute {
          json = EmployerHelper.employers_and_broker_agency(current_user, params[:id]) if SecurityHelper.can_view_employer_list?(current_user, params[:id])
          json ? (render json: json) :
              (render json: {error: 'no broker agency profile found'}, :status => :not_found)
        }
      end

      def employer_details
        execute {
          details = EmployerHelper.employer_details(@employer_profile, params[:report_date]) if @employer_profile && SecurityHelper.can_view_employer_details?(current_user)
          details ? (render json: details) : (render json: {file: 'public/404.html'}, status: :not_found)
        }
      end

      def employee_roster
        execute {
          employees = EmployeeHelper.employees_sorted_by @employer_profile, params[:employee_name], params[:status] if @employer_profile && SecurityHelper.can_view_employee_roster?(current_user)
          employees ? (render json: {
              employer_name: @employer_profile.legal_name,
              total_num_employees: employees.size,
              roster: EmployeeHelper.roster_employees(employees.limit(500).to_a, @employer_profile.renewing_published_plan_year.present?)
          }) : (render json: {error: 'no employee roster found'}, :status => :not_found)
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