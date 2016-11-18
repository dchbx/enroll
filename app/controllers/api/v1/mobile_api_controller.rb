module Api
  module V1
    class MobileApiController < ApplicationController
      include Api::V1::Mobile::Renderer

      before_filter :employer_profile, except: :employers_list

      def employers_list
        execute {
          authorized = Api::V1::Mobile::Security.new(user: current_user, params: params).authorize_employer_list
          if authorized[:status] == 200
            employer = Api::V1::Mobile::Employer.new authorized: authorized, user: current_user
            render_employers_list employer.employers_and_broker_agency
          else
            render_employers_list_error authorized[:status]
          end
        }
      end

      def employer_details
        execute {
          if Api::V1::Mobile::Security.new(user: current_user, employer_profile: @employer_profile).can_view_employer_details?
            employer = Api::V1::Mobile::Employer.new employer_profile: employer_profile, report_date: params[:report_date]
            render_employer_details employer.details
          else
            render_employer_details_error
          end
        }
      end

      def employee_roster
        execute {
          if Api::V1::Mobile::Security.new(user: current_user, employer_profile: @employer_profile).can_view_employee_roster?
            employees = Api::V1::Mobile::Employee.new(employer_profile: @employer_profile,
                                                      employee_name: params[:employee_name],
                                                      status: params[:status]).employees_sorted_by
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
          message = ([:development, :test].include?(Rails.env.to_sym)) ? e.backtrace : e.message
          render json: {error: message}, :status => :internal_server_error
        end
      end

      def employer_profile
        @employer_profile ||= EmployerProfile.find params[:employer_profile_id]
      end

    end
  end
end