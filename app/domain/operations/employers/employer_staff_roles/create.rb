# frozen_string_literal: true

module Operations
  module Employers
    module EmployerStaffRoles
      # New Staff operation is to initialize new employer staff with ability for self coverage
      # This will return an entity
      class Create
        include Dry::Monads[:result, :do, :try]

        def call(params:, profile:)
          constructed_params = yield construct_params(params[:coverage_record], profile)
          values = yield validate(constructed_params)
          employer_staff_entity = yield persist(values)

          Success(employer_staff_entity)
        end

        private

        def construct_params(params, profile)
          address = params[:address]
          email = params[:email]
          Success({
            is_owner: false,
            benefit_sponsor_employer_profile_id: profile.id,
            coverage_record: {
              ssn: params[:ssn],
              gender: params[:gender],
              dob: params[:dob],
              hired_on: params[:hired_on],
              is_applying_coverage: params[:is_applying_coverage],
              address: {
                kind: address[:kind],
                address_1: address[:kind],
                address_2: address[:address_2],
                address_3: address[:address_3],
                city: address[:city],
                county: address[:county],
                state: address[:state],
                location_state_code: address[:location_state_code],
                full_text: address[:full_text],
                zip: address[:zip],
                country_name: address[:country_name]
              },
              email: {
                kind: email[:kind],
                address: email[:address]
              }
            }
          })
        end

        def validate(constructed_params)
          result = Validators::Employers::EmployerStaffRoleContract.new.call(constructed_params)
          if result.success?
            Success(result.to_h)
          else
            Failure('Unable to build Employer staff role')
          end
        end

        def persist(values)
          Success(Entities::EmployerStaffRole.new(values))
        end
      end
    end
  end
end
