module Queries
  module People
    class AgencyStaffDetailQuery
      attr_reader :person_id

      def initialize(person_id)
        @person_id = person_id
      end

      def person
        @person = Person.find(person_id)
      end

      def policy_class
        AngularAdminApplicationPolicy
      end
    end
  end
end