# frozen_string_literal: true

module Operations
  module Employers
    # New Staff operation is to initialize new employer staff with ability for self coverage
    # This will return an entity, which we use in our ERB files.
    class NewEmployerStaff
      include Dry::Monads[:result, :do, :try]

      def call(params)
        person = yield find_person(params[:id])
        employer_staff_params = yield construct_employer_staff_params(person)
        staff_entity = yield get_staff_entity(employer_staff_params)

        Success(staff_entity.value!)
      end

      private

      def find_person(id)
        Operations::People::Find.new.call({person_id: id})
      end

      def construct_employer_staff_params(person)
        home_address = person.home_address
        email = person.work_email || person.home_email
        Success(
          {
            person_id: person.id.to_s,
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob,
            email: person.work_email_or_best,
            area_code: person.work_phone&.area_code,
            number: person.work_phone&.number,
            coverage_record: {
              ssn: person.ssn,
              gender: person.gender,
              dob: person.dob,
              hired_on: nil,
              is_applying_coverage: false,
              address: {
                kind: 'home',
                address_1: home_address&.kind,
                address_2: home_address&.address_2,
                address_3: home_address&.address_3,
                city: home_address&.city,
                county: home_address&.county,
                state: home_address&.state,
                location_state_code: home_address&.location_state_code,
                full_text: home_address&.full_text,
                zip: home_address&.zip,
                country_name: home_address&.country_name
              },
              email: {
                kind: email&.kind,
                address: email&.address
              }
            }
          }
        )
      end

      # def validate_employer_staff_params(params)
      #   result = Validators::StaffContract.new.call(params)
      #   if result.success?
      #     Success(result.to_h)
      #   else
      #     Failure(result.errors.to_h)
      #   end
      # end

      def get_staff_entity(params)
        Try do
          Success(Entities::Forms::Employers::NewEmployerStaff.new(params))
        end.or(Failure({:message => ['Invalid Params']}))
      end
    end
  end
end
