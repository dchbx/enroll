# frozen_string_literal: true

module Parsers::Xml::Cv
  class VerificationsParser
    include HappyMapper

    element :is_lawfully_present, Boolean, tag: 'lawful_presence_verification_results/ns0:is_lawfully_present'
    element :citizen_status, String, tag: 'lawful_presence_verification_results/ns0:citizen_status'
    element :residency_verification_results, String

    def to_hash
      {
        lawful_presence_verification_results: {
          is_lawfully_present: is_lawfully_present,
          citizen_status: citizen_status.split('#').last
        },
        residency_verification_results: residency_verification_results.split('#').last
      }
    end
  end
end
