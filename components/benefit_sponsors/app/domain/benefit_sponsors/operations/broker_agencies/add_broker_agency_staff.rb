# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module BrokerAgencies
      # Persist Staff operation is to persist broker staff role
      class AddBrokerAgencyStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          values = yield validate_params(params)
          @profile = yield fetch_profile(values[:profile_id])
          @person = yield fetch_person(values[:person_id])
          _value = yield check_if_broker_staff_role_already_exists?
          terminated_staff = yield check_if_terminated_staff_exists?
          result = if terminated_staff.present?
                     yield move_staff_to_pending(terminated_staff)
                   else
                     broker_staff_entity = yield create_broker_staff_record
                     yield persist(broker_staff_entity)
                   end

          Success(result)
        end

        private

        def validate_params(params)
          result = BenefitSponsors::Validators::BrokerAgencies::BrokerAgencyStaffRoles::AddBrokerStaffRoleContract.new.call(params)
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

        def check_if_broker_staff_role_already_exists?
          if @person.broker_agency_staff_roles.where(:aasm_state.ne => "broker_agency_terminated").map(&:benefit_sponsors_broker_agency_profile_id).map(&:to_s).include? @profile.id.to_s
            Failure({:message => 'Already staff role exists for the selected organization'})
          else
            Success({})
          end
        end

        def check_if_terminated_staff_exists?
          Success(@person.broker_agency_staff_roles.detect{|role| role if role.benefit_sponsors_broker_agency_profile_id == @profile.id && role.aasm_state == "broker_agency_terminated"})
        end

        def move_staff_to_pending(terminated_staff)
          terminated_staff.broker_agency_pending!
          Success({:message => 'Successfully moved broker staff role from terminated to pending'})
        end

        def create_broker_staff_record
          BenefitSponsors::Operations::BrokerAgencies::BrokerAgencyStaffRoles::Create.new.call(profile: @profile)
        end

        def persist(broker_entity)
          result = Try do
            @person.broker_agency_staff_roles << BrokerAgencyStaffRole.new(broker_entity.to_h)
            @person.save!
            user = @person.user
            if user && !user.roles.include?("broker_agency_staff")
              user.roles << "broker_agency_staff"
              user.save!
            end
            Success({:message => 'Successfully added broker staff role'})
          end
          result.to_result.failure? ? Failure({:message => 'Failed to create records, contact HBX Admin'}) : result.to_result.value!
        end
      end
    end
  end
end
