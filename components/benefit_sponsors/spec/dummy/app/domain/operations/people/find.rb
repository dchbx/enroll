# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class Find
      include Dry::Monads[:result, :do]


      def call(params)
        person = yield fetch_person(params[:person_id])

        Success(person)
      end

      private

      def fetch_person(person_id)
        person = Person.where(id: person_id).first

        if person
          Success(person)
        else
          Failure({:message => ['Person not found']})
        end
      end
    end
  end
end
