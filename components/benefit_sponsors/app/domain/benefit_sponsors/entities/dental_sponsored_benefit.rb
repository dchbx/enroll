# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class DentalSponsoredBenefit < SponsoredBenefit
      transform_keys(&:to_sym)

      attribute :elected_product_choices, Types::Array.optional.meta(omittable: true)
    end
  end
end
