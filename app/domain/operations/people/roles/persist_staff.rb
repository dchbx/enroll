# frozen_string_literal: true

module Operations
  module People
    module Roles
      class PersistStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          profile = yield fetch_profile(params[:profile_id])
          person = yield fetch_person(params[:person_id])
          result = yield persist(person, profile.value!)

          Success(result.value!)
        end

        private

        def fetch_profile(id)
          Try do
            profile = BenefitSponsors::Organizations::Profile.find(id)

            if profile
              Success(profile)
            else
              Failure({:message => ['Profile not found']})
            end
          end.or(Failure({:message => ['Profile not found']}))
        end

        def fetch_person(id)
          person = Person.where(id: id).first

          if person
            Success(person)
          else
            Failure({:message => ['Person not found']})
          end
        end

        def persist(person, profile)
          Try do
            person.employer_staff_roles << EmployerStaffRole.new(
              person: person,
              :benefit_sponsor_employer_profile_id => profile.id,
              is_owner: false,
              aasm_state: 'is_applicant'
            )
            person.save!
            user = person.user
            if user && !user.roles.include?("employer_staff")
              user.roles << "employer_staff"
              user.save!
            end
            Success({:message => ['Successfully added employer staff role']})
          end.or(Failure({:message => ['Failed while saving person/user']}))
        end
      end
    end
  end
end
