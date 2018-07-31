module BenefitMarkets
  module SponsoredBenefits
    class SponsoredBenefitFactory

      def initialize(product_kind)
        validate_product_kind!(product_kind)

        klass_name = sponsored_benefit_class_name_for(product_kind)
        @sponsored_benefit  = klass_name.constantize.new
        @product_kind       = product_kind
      end

      def product_package_kind=(new_product_package_kind)
        validate_product_package_kind!(new_product_package_kind)

        @sponsored_benefit.product_package = product_package_class_name.constantize.new
        @product_package_kind = product_package_kind
      end

      def sponsored_benefit
        @sponsored_benefit
      end

      def add_product_list(new_product_list)
      end

      private




      def sponsored_benefit_class_name_for(product_kind)
        "#{product_kind}_sponsored_benefit"
      end

      def set_sponsored_benefit
        if @product_kind.present? && @product_package_kind.present?
          namespace = namespace_for(self)
        end        
      end

      def add_contribution_model(new_contribution_model)
        @sponsored_benefit.contribution_model = new_contribution_model
      end

      def add_sponsor_eligibility_policy(new_sponsor_eligibility_policy)
        @sponsored_benefit.eligibility_policies << new_sponsor_eligibility_policy
      end

      def add_member_eligibility_policy(new_member_eligibility_policy)
        @sponsored_benefit.eligibility_policies << new_member_eligibility_policy
      end

      def product_class_name
        klass_name = "#{@product_kind}_product".camelcase
        product_kind_namespace + "::#{klass_name}"
      end

      def product_package_class_name
        klass_name = "#{@product_package_kind}_#{@product_kind.to_s}_product_package".camelcase
        product_kind_namespace + "::#{klass_name}"
      end

      def product_namespace
        local_namespace   = self.class.to_s.deconstantize
        local_namespace.deconstantize + "::Products"
      end

      def contribution_model_namespace
        local_namespace   = parent_namespace_for(self.class)
        parent_namespace_for(local_namespace) + "::ContributionModels"
      end

      def product_kind_namespace
        product_dir = "#{@product_kind}_products".camelcase
        [product_namespace, product_dir].join("::")
      end

      def validate_product_kind!(product_kind, product_package_kind)
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
