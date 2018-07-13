module BenefitMarkets
  module Products
    class ProductPackagePolicy
      def initialize(current_user, product_package)
        @user = current_user
        @product_package = product_package
      end

      def show?
        true
      end
    end
  end
end
