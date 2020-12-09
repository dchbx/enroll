# frozen_string_literal: true

module Operations
  module People
    module Roles
      class PersistStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          params   =    yield validate_params(params)
          profile  =    yield fetch_profile(params[:profile_id])
          person   =    yield fetch_person(params[:person_id])
          result   =    yield persist(person, profile, params[:coverage_record])

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

        def persist(person, profile, params)
          result = Try do
            employer_ids = person.employer_staff_roles.where(:aasm_state.ne => :is_closed).map(&:benefit_sponsor_employer_profile_id).map(&:to_s)
            if employer_ids.include? profile.id.to_s
              Failure({:message => 'Already exists a staff role for the selected organization'})
            else
              person.employer_staff_roles << EmployerStaffRole.new(
                person: person,
                :benefit_sponsor_employer_profile_id => profile.id,
                is_owner: false,
                aasm_state: 'is_applicant',
                coverage_record: CoverageRecord.new(
                  ssn: params[:ssn],
                  dob: params[:dob],
                  hired_on: params[:hired_on],
                  is_applying_coverage: params[:is_applying_coverage],
                  gender: params[:gender]
                )
              )
              person.save!
              user = person.user
              if user && !user.roles.include?("employer_staff")
                user.roles << "employer_staff"
                user.save!
              end
              Success({:message => 'Successfully added employer staff role'})
            end
          end
          result.to_result.failure? ? Failure({:message => 'Failed while saving records'}) : result.to_result.value!
        end
      end
    end
  end
end
