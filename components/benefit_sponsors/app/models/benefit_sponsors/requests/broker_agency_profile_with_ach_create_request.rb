# frozen_string_literal: true

require 'dry-initializer'
require 'dry-types'
require 'mail'

module BenefitSponsors
  module Requests
    class AchInformation
      extend Dry::Initializer

      option :ach_account, Dry::Types['coercible.string'], optional: true
      option :ach_account, Dry::Types['coercible.string'], optional: true
      option :ach_routing, Dry::Types['coercible.string'], optional: true
      option :ach_routing_confirmation, Dry::Types['coercible.string'], optional: true
    end

    class BrokerAgencyProfileWithAchCreateRequest < BrokerAgencyProfileCreateRequest
      option :ach_information, ->(args) { ::BenefitSponsors::Requests::AchInformation.new(args) }, optional: true
    end
  end
end
