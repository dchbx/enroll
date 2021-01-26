# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Profiles
      # Entity acts a top level profile class
      class AcaShopDcEmployerProfile < Profile
        include Dry::StructExtended

        attribute :is_benefit_sponsorship_eligible,    Types::Strict::Bool
      end
    end
  end
end