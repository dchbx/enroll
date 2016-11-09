require_relative '../../../../lib/api/v1/employer_helper'
require_relative '../../../../lib/api/v1/renderer_helper'

module Api
  module V1
    class MobileApiController < ApplicationController
      include RendererHelper

      before_filter :employer_profile, except: :employers_list

      def employers_list
        execute {
          auth = SecurityHelper.authorize_employer_list current_user, params
          if auth[:status] == 200
            render_employers_list EmployerHelper.employers_and_broker_agency current_user, auth
          else
            render_employers_list_error auth[:status]
          end
        }
      end

      def employer_details
        execute {
          if SecurityHelper.can_view_employer_details? current_user, @employer_profile
            render_employer_details EmployerHelper.employer_details(@employer_profile, params[:report_date])
          else
            render_employer_details_error
          end
        }
      end

      def employee_roster
        execute {
          if SecurityHelper.can_view_employee_roster? current_user, @employer_profile
            employees = EmployeeHelper.employees_sorted_by @employer_profile, params[:employee_name], params[:status]
            employees ? render_employee_roster(employees) : render_employee_roster_error
          else
            render_employee_roster_error
          end
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
        @employer_profile ||= EmployerProfile.find params[:employer_profile_id]
      end

    end
  end
end