module Api
  module V1
    module Mobile
      module RendererUtil
        NO_BROKER_AGENCY_PROFILE_FOUND = 'no broker agency profile or broker role found'
        NO_EMPLOYER_DETAILS_FOUND = 'no employer details found'
        NO_EMPLOYEE_ROSTER_FOUND = 'no employee roster found'

        def render_employers_list response
          if response
            render json: response
          else
            render_employers_list_error :not_found
          end
        end

        def render_employers_list_error status
          render json: {error: NO_BROKER_AGENCY_PROFILE_FOUND}, status: status
        end

        def render_employer_details details
          if details
            render json: details
          else
            render_employer_details_error
          end
        end

        def render_employer_details_error
          render json: {error: NO_EMPLOYER_DETAILS_FOUND}, status: :not_found
        end

        def render_employee_roster employees
          render json: {
              employer_name: @employer_profile.legal_name,
              total_num_employees: employees.size,
              roster: EmployeeUtil.new(employees: employees.limit(500).to_a, employer_profile: @employer_profile).roster_employees}
        end

        def render_employee_roster_error
          render json: {error: NO_EMPLOYEE_ROSTER_FOUND}, :status => :not_found
        end

      end
    end
  end
end