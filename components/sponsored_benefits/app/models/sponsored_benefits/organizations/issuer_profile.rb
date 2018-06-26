module SponsoredBenefits
  module Organizations
    class IssuerProfile < Profile
      include Mongoid::Document
      include Mongoid::Timestamps



      def benefit_products
      end

      def benefit_products_by_effective_date(effective_date)
      end

    end 
  end
end
