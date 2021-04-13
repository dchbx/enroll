# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module Employers
      # Persist Staff operation is to persist employer staff with ability for self coverage
      class AddEmployerStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          values = yield validate_params(params)
          @profile = yield fetch_profile(values[:profile_id])
          @person = yield fetch_person(values[:person_id])
          _value = yield check_if_employer_staff_role_already_exists?
          _contact_info = yield update_contact_info(values)
          employer_staff_entity = yield create_employer_staff_record(values)
          result = yield persist(employer_staff_entity)

          Success(result)
        end

        private

        def validate_params(params)
          result = BenefitSponsors::Validators::Employers::EmployerStaffRoles::AddEmployerStaffContract.new.call(params)
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
          ::Operations::People::Find.new.call({person_id: id})
        end

        def check_if_employer_staff_role_already_exists?
          if @person.employer_staff_roles.where(:aasm_state.ne => :is_closed).map(&:benefit_sponsor_employer_profile_id).map(&:to_s).include? @profile.id.to_s
            Failure({:message => 'Already staff role exists for the selected organization'})
          else
            Success({})
          end
        end

        def update_contact_info(values)
          if values[:area_code].present?
            Success(@person.contact_info(values[:email], values[:area_code], values[:number], nil))
          elsif values[:email]
            Success(@person.add_work_email(values[:email]))
          end
        end

        def create_employer_staff_record(values)
          BenefitSponsors::Operations::Employers::EmployerStaffRoles::Create.new.call(params: values, profile: @profile)
        end

        def persist(er_entity)
          result = Try do
            @person.employer_staff_roles << EmployerStaffRole.new(er_entity.to_h)
            @person.save!
            user = @person.user
            if user && !user.roles.include?("employer_staff")
              user.roles << "employer_staff"
              user.save!
            end
            Success({:message => 'Successfully added employer staff role', :person => @person})
          end
          result.to_result.failure? ? Failure({:message => 'Failed to create records, contact HBX Admin'}) : result.to_result.value!
        end
      end
    end
  end
end
