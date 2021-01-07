# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module BrokerAgencies
      module BrokerAgencyStaffRoles
        # New Staff operation is to initialize new broker staff
        # This will return an entity
        class Create
          include Dry::Monads[:result, :do, :try]

          def call(profile:)
            constructed_params = yield construct_params(profile)
            values = yield validate(constructed_params)
            broker_staff_entity = yield persist(values)

            Success(broker_staff_entity)
          end

          private

          def construct_params(profile)
            Success({
                      benefit_sponsors_broker_agency_profile_id: profile.id,
                      aasm_state: 'broker_agency_pending'
                    })
          end

          def validate(constructed_params)
            result = BenefitSponsors::Validators::BrokerAgencies::BrokerAgencyStaffRoles::BrokerStaffRoleContract.new.call(constructed_params)
            if result.success?
              Success(result.to_h)
            else
              Failure('Unable to build broker agency staff role')
            end
          end

          def persist(values)
            Success(BenefitSponsors::Entities::BrokerAgencies::BrokerAgencyStaffRoles::BrokerAgencyStaffRole.new(values))
          end
        end
      end
    end
  end
end
