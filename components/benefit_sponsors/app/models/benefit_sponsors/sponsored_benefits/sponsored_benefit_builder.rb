# 
module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitBuilder

      attr_reader :sponsored_benefit

      def self.build
        builder = new
        yield(builder)
        builder.sponsored_benefit
      end

      def initialize
        @sponsored_benefit = nil
        # @sponsored_benefit = sponsored_benefit.new
      end

      def add_benefit_products(new_benefit_products)
        @sponsored_benefit.benefit_products = new_benefit_products
      end

      def add_sponsor_contribution(new_sponsor_contribution)
        @sponsored_benefit.sponsor_contribution = new_sponsor_contribution
      end

      def add_sponsor_eligibility_policy(new_sponsor_eligibility_policy)
        @sponsored_benefit.eligibility_policies << new_sponsor_eligibility_policy
      end

      def add_member_eligibility_policy(new_member_eligibility_policy)
        @sponsored_benefit.eligibility_policies << new_member_eligibility_policy
      end

      def sponsored_benefit
        @sponsored_benefit
      end

      private

      def set_sponsored_benefit
        if @product_kind.present? && @product_package_kind.present?
          namespace = namespace_for(self)
        end        
      end

      def product_package_class_name

        klass_name = "#{@product_package_kind}_#{@product_kind.to_s}_product_package"
        config_klass = "#{kind.to_s}_configuration".camelcase
      end

      def product_namespace
        local_namespace = self.class.to_s.deconstantize
        local_namespace.deconstantize + "::Products"
      end

      def validate_product_kind!(product_kind)
        unless BenefitMarkets::Products::Product::KINDS.include?(product_kind)
          raise "invalid Product kind: #{product_kind}"
        end
      end

      def validate_product_package_kind!(product_package_kind)

        unless BenefitMarkets::Products::ProductPackage::KINDS.include?(product_package_kind)
          raise "invalid Product Package kind: #{product_package_kind}"
        end
      end



    end
  end
end
