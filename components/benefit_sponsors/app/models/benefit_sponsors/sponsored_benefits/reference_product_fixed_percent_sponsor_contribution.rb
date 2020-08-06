# frozen_string_literal: true

module BenefitSponsors
  module SponsoredBenefits
    class ReferenceProductFixedPercentSponsorContribution < FixedPercentSponsorContribution
      field :reference_product_id, type: BSON::ObjectId

      # Return the reference product for calculation.
      # @return [::BenefitMarkets::Products::Product] the reference product
      attr_reader :reference_product

      attr_writer :reference_product
    end
  end
end
