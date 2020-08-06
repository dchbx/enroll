# frozen_string_literal: true

module BenefitSponsors
  module BrokerAgencyRegistration
    module CreateRequestWithAchValidators
      class PARAMS < ::BenefitSponsors::BrokerAgencyRegistration::CreateRequestValidators::PARAMS
        define do
          required(:ach_information).schema do
            required(:ach_account).value(:filled?)
            optional(:ach_routing).maybe(:str?)
            optional(:ach_routing_confirmation).maybe(:str?)
          end
        end
      end
    end
  end
end