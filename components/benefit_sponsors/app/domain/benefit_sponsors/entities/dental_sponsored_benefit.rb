# frozen_string_literal: true

module BenefitSponsors
  module Entities
    # This class shows the list of required and optional attributes
    # that are required to build a new dental sponsored benefit object
    class DentalSponsoredBenefit < SponsoredBenefit
      transform_keys(&:to_sym)

      attribute :elected_product_choices, Types::Array.optional.meta(omittable: true)
    end
  end
end
