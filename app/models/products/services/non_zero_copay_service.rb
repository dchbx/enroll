# frozen_string_literal: true

module Products
  module Services
    class NonZeroCopayService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        if record.co_insurance_in_network_tier_1.include?("Not Applicable") #ticket_42679
          number = record.copay_in_network_tier_1.delete('^0-9')
          # number, _string = record.copay_in_network_tier_1.split(/\ (?=[\w])/)
          if DRUG_DEDUCTIBLE_OPTIONS.include?(record.visit_type)
            "$#{number} per prescription"
          else
            "$#{number} per visit"
          end
        else
          ""
        end
      end
    end
  end
end
