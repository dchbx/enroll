# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module BrokerAgencies
      module Forms
        # New Staff operation is to initialize new broker staff
        # This will return an entity, which we use in our ERB files.
        class NewBrokerAgencyStaff
          include Dry::Monads[:result, :do, :try]

          def call(params)
            validated_params = yield validate(params)
            person = yield find_person(validated_params[:id])
            broker_staff_params = yield construct_broker_staff_params(person)
            staff_entity = yield get_broker_staff_entity(broker_staff_params)

            Success(staff_entity.value!)
          end

          private

          def validate(params)
            if params[:id].present?
              Success(params)
            else
              Failure({:message => ['person_id is expected']})
            end
          end

          def find_person(id)
            ::Operations::People::Find.new.call({person_id: id})
          end

          def construct_broker_staff_params(person)
            Success(
              {
                person_id: person.id.to_s,
                first_name: person.first_name,
                last_name: person.last_name,
                dob: person.dob,
                email: person.work_email_or_best
              }
            )
          end

          def get_broker_staff_entity(params)
            Try do
              Success(BenefitSponsors::Entities::Forms::BrokerAgencies::BrokerAgencyStaffRoles::New.new(params))
            end.or(Failure({:message => ['Invalid Params']}))
          end
        end
      end
    end
  end
end
