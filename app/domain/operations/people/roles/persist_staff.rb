# frozen_string_literal: true

module Operations
  module People
    module Roles
      class PersistStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          params   = yield validate_params(params)
          profile  = yield fetch_profile(params[:profile_id])
          person   = yield fetch_person(params[:person_id])
          yield check_existing_staff(person, params[:profile_id])
          result   = yield persist(person, profile, params[:coverage_record])

          Success(result)
        end

        private

        def validate_params(params)
          result = Validators::StaffContract.new.call(params)
          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors.to_h)
          end
        end

        def fetch_profile(id)
          result = Try do
            profile = BenefitSponsors::Organizations::Profile.find(id)

            if profile
              Success(profile)
            else
              Failure({:message => 'Profile not found'})
            end
          end
          result.to_result.failure? ? Failure({:message => 'Profile not found'}) : result.to_result.value!
        end

        def fetch_person(id)
          person = Person.where(id: id).first

          if person
            Success(person)
          else
            Failure({:message => 'Person not found'})
          end
        end

        def check_existing_staff(person, profile_id)
          if person.employer_staff_roles.where(:aasm_state.ne => :is_closed).map(&:benefit_sponsor_employer_profile_id).map(&:to_s).include? profile_id.to_s
            Failure({:message => 'Already staff role exists for the selected organization'})
          else
            Success({})
          end
        end

        def persist(person, profile, params)
          result = Try do
            address = params[:address]
            email = params[:email]
            coverage_record = CoverageRecord.new(
              ssn: params[:ssn],
              dob: params[:dob],
              hired_on: params[:hired_on],
              is_applying_coverage: params[:is_applying_coverage],
              gender: params[:gender],
              address: Address.new({kind: address[:kind],
                                    address_1: address[:kind],
                                    address_2: address[:address_2],
                                    address_3: address[:address_3],
                                    city: address[:city],
                                    county: address[:county],
                                    state: address[:state],
                                    location_state_code: address[:location_state_code],
                                    full_text: address[:full_text],
                                    zip: address[:zip],
                                    country_name: address[:country_name]}),
              email: Email.new({kind: email[:kind],
                                address: email[:address]})
            )
            person.employer_staff_roles << EmployerStaffRole.new(
              person: person,
              :benefit_sponsor_employer_profile_id => profile.id,
              is_owner: false,
              aasm_state: 'is_applicant',
              coverage_record: coverage_record
            )
            person.save!
            user = person.user
            if user && !user.roles.include?("employer_staff")
              user.roles << "employer_staff"
              user.save!
            end
            Success({:message => 'Successfully added employer staff role'})
          end
          result.to_result.failure? ? Failure({:message => 'Failed to create records, contact HBX Admin'}) : result.to_result.value!
        end
      end
    end
  end
end
