module Api
  module V1
    class MobileApiController < ApplicationController
      include Api::V1::Mobile::RendererUtil

      before_filter :employer_profile, except: [:employers_list, :my_employee_roster, :my_employer_details]
      Mobile = Api::V1::Mobile

      def employers_list
        execute {
          authorized = Mobile::SecurityUtil.new(user: current_user, params: params).authorize_employer_list
          if authorized[:status] == 200
            employer = Mobile::EmployerUtil.new authorized: authorized, user: current_user
            render_employers_list employer.employers_and_broker_agency
          else
            render_employers_list nil, authorized[:status]
          end
        }
      end

      def employer_details
        execute {
          can_view = Mobile::SecurityUtil.new(user: current_user, employer_profile: @employer_profile).can_view_employer_details?
          render_employer can_view
        }
      end

      def my_employer_details
        execute {
          @employer_profile ||= Mobile::EmployerUtil.employer_profile_for_user current_user
          render_employer !@employer_profile.nil?
        }
      end

      def employee_roster
        execute {
          can_view = Mobile::SecurityUtil.new(user: current_user, employer_profile: @employer_profile).can_view_employee_roster?
          render_employees can_view
        }
      end

      def my_employee_roster
        execute {
          @employer_profile ||= Mobile::EmployerUtil.employer_profile_for_user current_user
          render_employees !@employer_profile.nil?
        }
      end

      #
      # Private
      #
      private

      def render_employer can_view
        execute {
          if can_view
            employer = Mobile::EmployerUtil.new employer_profile: @employer_profile, report_date: params[:report_date]
            render_employer_details employer.employer_details
          else
            render_employer_details
          end
        }
      end

      def render_employees can_view
        execute {
          if can_view
            employees = Mobile::EmployeeUtil.new(employer_profile: @employer_profile,
                                                 employee_name: params[:employee_name],
                                                 status: params[:status]).employees_sorted_by
            employees ? render_employee_roster(employees) : render_employee_roster
          else
            render_employee_roster
          end
        }
      end

      def execute
        begin
          yield
        rescue Exception => e
          logger.error "Exception caught in employer_details: #{e.message}"
          e.backtrace.each { |line| logger.error line }
          message = ([:development, :test].include?(Rails.env.to_sym)) ? [e.message] + e.backtrace : e.message
          render json: {error: message}, :status => :internal_server_error
        end
      end

      def employer_profile
        @employer_profile ||= EmployerProfile.find params[:employer_profile_id]
      end

    end
  end
end