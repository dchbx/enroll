module BenefitMarkets
  module Products
    class ProductPackageFormPolicy
      def initialize(current_user, product_package_form)
        @user = current_user
        @product_package_form = product_package_form
        # We will need this if the authorization logic starts to look at 
        # the actual package
        @form_service = ::BenefitMarkets::Products::ProductPackageService.new
      end

      def new?
        true
      end

      def create?
        true
      end

      def edit?
        true
      end

      def update?
        true
      end
    end
  end
end
