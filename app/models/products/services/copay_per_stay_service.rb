# frozen_string_literal: true

module Products
  module Services
    class CopayPerStayService < BaseService

      attr_accessor :record

      def initialize(record)
        @record = record
      end

      def in_network_process
        number, _string = record.copay_in_network_tier_1.split(/\ (?=[\w])/)
        if record.copay_in_network_tier_1.include?("after deductible") #ticket_42688
          "You must meet the deductible first, then #{number} per stay." if record.co_insurance_in_network_tier_1.include?("Not Applicable") || record.co_insurance_in_network_tier_1.delete("%").to_i == 100 #tickets 42694, 42688
        elsif record.copay_in_network_tier_1.include?("with deductible") #ticket_42688
          "You pay #{number} copay per stay. You are also responsible for any remaining allowed charges, which will accrue towards your yearly deductible." if record.co_insurance_in_network_tier_1.include?("Not Applicable") #tickets_42690
        elsif record.co_insurance_in_network_tier_1.include?("Not Applicable") #ticket_42686
          "#{number} copay per stay"
        elsif record.co_insurance_in_network_tier_1.delete("%").to_i == 100 && number.to_i.zero? #ticket_42695
          "Not covered. You are responsible for the full cost."
        end
      end

      def out_network_process
        number, _string = record.copay_out_of_network.split(/\ (?=[\w])/)
        if record.copay_out_of_network.include?("after deductible")
          "You must first meet the out-of-network deductible, then #{number} per stay." if record.co_insurance_out_of_network.include?("Not Applicable") || record.co_insurance_out_of_network.delete("%").to_i == 100 #tickets 42694, 42688
        elsif record.copay_out_of_network.include?("with deductible")
          "You pay #{number} copay per stay. You are also responsible for any remaining allowed charges, which will accrue towards your yearly out-of-network deductible." if record.co_insurance_out_of_network.include?("Not Applicable") #tickets_42690
        elsif record.co_insurance_out_of_network.delete("%").to_i == 100 && number.to_i.zero? #ticket_42695
          "Not covered. You are responsible for the full cost."
        end
      end

    end
  end
end
