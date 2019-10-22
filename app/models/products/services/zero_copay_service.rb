# frozen_string_literal: true

module Products
  module Services
    class ZeroCopayService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        if NO_CHARGE.include?(record.co_insurance_in_network_tier_1) #ticket_42676
          NO_CHARGE
        elsif record.co_insurance_in_network_tier_1.include?("Coinsurance after deductible") && DEVICES.exclude?(record.visit_type) #ticket_42678
          number, _string = record.co_insurance_in_network_tier_1.split(/\ (?=[\w])/)
          "You must meet the deductible first, then #{number} of allowed charges"
        elsif record.co_insurance_in_network_tier_1.gsub("%","").to_i.zero? #ticket_42674
          NO_CHARGE
        elsif record.co_insurance_in_network_tier_1.gsub("%","").to_i == 100 #ticket_42675
          "Not covered. You are responsible for the full cost"
        end
      end

      def out_network_process
        if record.co_insurance_out_of_network.include?("Coinsurance after deductible") && DEVICES.include?(record.visit_type) #ticket_42678
          number, _string = record.co_insurance_out_of_network.split(/\ (?=[\w])/)
          "You must meet the out-of-network deductible first, then #{number} of allowed charges per device."

        #WIP
        # elsif NO_CHARGE.include?(record.co_insurance_out_of_network)
        #     NO_CHARGE
        # elsif record.co_insurance_out_of_network.gsub("%","").to_i.zero?
        #   NO_CHARGE
        # elsif record.co_insurance_out_of_network.gsub("%","").to_i == 100
        #   "Not covered. You are responsible for the full cost"
        end
      end
    end
  end
end
