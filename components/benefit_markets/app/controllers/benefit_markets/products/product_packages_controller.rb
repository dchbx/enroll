module BenefitMarkets
  module Products
    class ProductPackagesController < ::BenefitMarkets::ApplicationController
      include Pundit
      before_filter :set_benefit_catalog, only: [ :show, :edit, :update, :destroy ]

      def new
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_new
        authorize @product_package
      end

      def create
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_create(package_params)
        authorize @product_package
        if @product_package.save
          redirect_to products_benefit_market_catalog_product_package_path(*@product_package.show_page_model)
        else
          render "new"
        end
      end

      def edit
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_edit(id: params[:id], benefit_catalog_id: params[:benefit_market_catalog_id])
        authorize @product_package
      end

      def update
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_update(id: params[:id], benefit_catalog_id: params[:benefit_market_catalog_id])
        authorize @product_package
        if @product_package.update_attributes(package_params)
          redirect_to products_benefit_market_catalog_product_package_path(*@product_package.show_page_model)
        else
          render "edit"
        end
      end

      def show
        @product_package = @benefit_catalog.product_packages.find(params[:id])
        authorize @product_package
      end

      private

      def set_benefit_catalog
        @benefit_catalog = BenefitMarkets::BenefitMarketCatalog.find(params[:benefit_market_catalog_id])
      end

      def package_params
        params.require(:product_package).permit(
          :package_kind,
          :health_package_kind,
          :dental_package_kind,
          :product_kind,
          :benefit_kind,
          :title,
          :multiplicity,
          :start_on,
          :end_on,
          :pricing_model_id,
          :contribution_model_id,
          :benefit_catalog_id,
          :issuer_id,
          :metal_level
        )
      end
    end
  end
end
