module FinancialAssistance
  module Factories
    # To call service, encode message, object to attr
    class AssistanceFactory
      include EventsHelper
      attr_accessor :person

      def initialize(person)
        @person = person
      end

      def search_existing_assistance
        status, @message = service.new(hashed_person).eligible_for_assistance?
        [status, encode_msg]
      end

      private

      def hashed_person
        {
          first_name: person.first_name,
          last_name: person.last_name,
          ssn: person.ssn,
          dob: simple_date_for(person.dob)
        }
      end

      def service
        FinancialAssistance::Services::AssistanceLookup
      end

      def encode_msg
        if @message == "faa.acdes_lookup"
          "101"
        elsif @message == "faa.curam_lookup"
          "010"
        end
      end
    end
  end
end
