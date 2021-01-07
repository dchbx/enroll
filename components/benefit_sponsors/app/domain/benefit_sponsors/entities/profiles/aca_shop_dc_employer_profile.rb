# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Profiles
      # Entity acts a top level profile class
      class AcaShopDcEmployerProfile < Profile
        transform_keys(&:to_sym)
      end
    end
  end
end