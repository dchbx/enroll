module Api
  module V1
    module Mobile
      module Renderer
        NO_BROKER_AGENCY_PROFILE_FOUND = 'no broker agency profile found'

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
          render json: {file: 'public/404.html'}, status: :not_found
        end

        def render_employee_roster employees
          render json: {
              employer_name: @employer_profile.legal_name,
              total_num_employees: employees.size,
              roster: Api::V1::Mobile::Employee.new(employees: employees.limit(500).to_a, employer_profile: @employer_profile).roster_employees}
        end

        def render_employee_roster_error
          render json: {error: 'no employee roster found'}, :status => :not_found
        end

      end
    end
  end
end