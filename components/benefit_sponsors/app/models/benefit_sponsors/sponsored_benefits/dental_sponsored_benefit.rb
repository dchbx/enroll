# frozen_string_literal: true

module BenefitSponsors
  module SponsoredBenefits
    class DentalSponsoredBenefit < SponsoredBenefit

      field :elected_product_choices, type: Array  # used for choice model to store employer preferences

      validate :verify_elected_choices

      def lookup_package_products(coverage_date)
        if multi_product?
          BenefitMarkets::Products::Product.by_coverage_date(elected_products, coverage_date)
        else
          super
        end
      end

      def elected_products
        products = product_package.products.by_service_areas(recorded_service_area_ids).where(:id.in => elected_product_choices)
        ::BenefitMarkets::Products::DentalProducts::DentalProduct.where(:id.in => products.pluck(:_id))
      end

      def renewal_elected_products_for(coverage_date)
        # adding compact as some of the products may not be available during renewal, compact will remove nil in such cases
        renewal_products = elected_products.collect(&:renewal_product).compact
        BenefitMarkets::Products::Product.by_coverage_date(renewal_products, coverage_date)
      end

      def attributes_for_renewal(new_benefit_package, new_product_package)
        renewal_attributes = super

        renewal_attributes.tap do |attributes|
          attributes[:elected_product_choices] = renewal_elected_products_for(new_benefit_package.start_on).map(&:id) if multi_product?
        end
      end

      def verify_elected_choices
        errors.add(:elected_product_choices, "can't be blank") if multi_product? && elected_product_choices.blank?
      end
    end
  end
end