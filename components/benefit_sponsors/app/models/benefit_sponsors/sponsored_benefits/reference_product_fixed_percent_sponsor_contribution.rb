module BenefitSponsors
  module SponsoredBenefits
    class ReferenceProductFixedPercentSponsorContribution < FixedPercentSponsorContribution
      field :reference_product_id, type: BSON::ObjectId
      
      # Return the reference product for calculation.
      # @return [::BenefitMarkets::Products::Product] the reference product
      def reference_product
        @reference_product
      end

      attr_writer :reference_product
    end
  end
end
