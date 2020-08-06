# frozen_string_literal: true

module Parsers::Xml::Cv
  class ResidencyVerificationResponse
    def self.parse(xml)
      self.new.tap do |me|
        me.parse(xml)
      end
    end

    def parse(xml)
      @parsed_obj = HappyMapper.parse(xml)
    end

    def to_hash
      {
        residency_verification_response: @parsed_obj.content.split('#').last
      }
    end
  end
end
