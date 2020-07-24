module FinancialAssistance
  module Services
    # this service will call assistance services and get the response code
    class AssistanceLookup
      attr_accessor :curam_response, :acdes_response
      attr_accessor :person_attr

      #we will received response code from the external service, converting to human readable format
      HUMANIZED_RESPONSE = {
        404 => true,
        302 => false,
        503 => false
      }.freeze

      def initialize(attr)
        @person_attr = attr
      end

      #If any of the response (acdes_response/curam_response) is true, this will return whether family can apply for assistance in FAA.
      def eligible_for_assistance?
        call_ext_lookup
        if acdes_response || curam_response
          [false, which_eligibility?]
        else
          [true, ""]
        end
      end

      def call_ext_lookup
        acdes_lookup
        curam_lookup
      end

      def curam_lookup
        status = curam_call.search_curam_financial_app(person_attr)
        @curam_response = HUMANIZED_RESPONSE[status]
      end

      def acdes_lookup
        status = acdes_call.search_aceds_app(person_attr)
        @acdes_response = HUMANIZED_RESPONSE[status]
      end

      private

      def which_eligibility?
        if acdes_response
          "faa.acdes_lookup"
        elsif curam_response
          "faa.curam_lookup"
        end
      end

      def curam_call
        CuramApplicationLookup
      end

      def acdes_call
        AcedsApplicationLookup
      end
    end
  end
end
