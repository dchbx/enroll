# frozen_string_literal: true

module Operations
  module People
    module Roles
      class NewStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          person_params = yield fetch_person(params[:id])
          params = yield validate_params(person_params)
          entity = yield get_entity(params)

          Success(entity.value!)
        end

        private

        def fetch_person(id)
          person = Person.where(id: id).first

          if person
            Success({first_name: person.first_name, last_name: person.last_name, dob: person.dob})
          else
            Failure({:message => ['Person not found']})
          end
        end

        def validate_params(params)
          result = Validators::StaffContract.new.call(params)
          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors.to_h)
          end
        end

        def get_entity(params)
          Try do
            Success(Entities::Staff.new(params))
          end.or(Failure({:message => ['Invalid Params']}))
        end
      end
    end
  end
end
