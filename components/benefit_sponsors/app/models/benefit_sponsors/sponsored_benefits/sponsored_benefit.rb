module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      SOURCE_KINDS  = [:benefit_sponsor_catalog, :conversion].freeze


      embedded_in :benefit_package, 
                  class_name: "::BenefitSponsors::BenefitPackages::BenefitPackage",
                  inverse_of: :sponsored_benefits

      field :product_package_kind,  type: Symbol
      field :product_option_choice, type: String # carrier id / metal level
      field :source_kind, type: Symbol, default: :benefit_sponsor_catalog

      belongs_to :reference_product, class_name: "::BenefitMarkets::Products::Product", inverse_of: nil, optional: true

      embeds_one  :sponsor_contribution, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"

      embeds_many :pricing_determinations, 
                  class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

      delegate :contribution_model, to: :product_package, allow_nil: true
      delegate :pricing_model, to: :product_package, allow_nil: true
      delegate :pricing_calculator, to: :product_package, allow_nil: true
      delegate :contribution_calculator, to: :product_package, allow_nil: true
      delegate :recorded_rating_area, to: :benefit_package
      delegate :recorded_service_area_ids, to: :benefit_package
      delegate :rate_schedule_date, to: :benefit_package
      delegate :benefit_sponsor_catalog, to: :benefit_package
      delegate :benefit_sponsorship, to: :benefit_package
      delegate :recorded_sic_code, to: :benefit_package

      validate :product_package_exists
#      validates_presence_of :sponsor_contribution

      default_scope { where(:source_kind.ne => :conversion) }

      def product_package_exists
        if product_package.blank? && source_kind == :benefit_sponsor_catalog
          self.errors.add(:base, "Unable to find mappable product package")
        end
      end

      def product_kind
        self.class.name.demodulize.split('SponsoredBenefit')[0].downcase.to_sym
      end

      # Don't remove this. Added it to get around mass assignment
      def kind=(kind)
        # do nothing
      end

      def health?
        product_kind == :health
      end

      def single_plan_type?
        product_package_kind == :single_product
      end

      def multi_product?
        product_package_kind == :multi_product
      end

      def products(coverage_date)
        lookup_package_products(coverage_date)
      end

      def lookup_package_products(coverage_date)
        return [reference_product] if product_package_kind == :single_product
        BenefitMarkets::Products::Product.by_coverage_date(product_package.products_for_plan_option_choice(product_option_choice).by_service_areas(recorded_service_area_ids), coverage_date)
      end

      def lowest_cost_product(effective_date)
        return @lowest_cost_product if defined? @lowest_cost_product
        sponsored_products =  products(effective_date)
        @lowest_cost_product = load_base_products(sponsored_products).min_by { |product|
          product.min_cost_for_application_period(effective_date)
        }
      end

      def highest_cost_product(effective_date)
        return @highest_cost_product if defined? @highest_cost_product
        sponsored_products =  products(effective_date)
        @highest_cost_product ||= load_base_products(sponsored_products).max_by { |product|
          product.max_cost_for_application_period(effective_date)
        }
      end

      def load_base_products(sponsored_products)
        return [] if sponsored_products.empty?
        @loaded_base_products ||= BenefitMarkets::Products::Product.find(sponsored_products.pluck(:_id))
      end

      def product_package
        return nil if product_package_kind.blank? || benefit_sponsor_catalog.blank?

        @product_package ||= benefit_sponsor_catalog.product_package_for(self)
      end

      # Changing the package kind should clear the package
      def product_package_kind=(pp_kind)
        if pp_kind != self.product_package_kind
          @product_package = nil
          write_attribute(:product_package_kind, pp_kind)
        end
      end

      def issuers_offered
        return [] if products(benefit_package.start_on).blank?

        products(benefit_package.start_on).pluck(:issuer_profile_id).uniq
      end

      def latest_pricing_determination
        pricing_determinations.sort_by(&:created_at).last
      end

      def renew(new_benefit_package)
        new_benefit_sponsor_catalog = new_benefit_package.benefit_sponsor_catalog
        new_product_package = new_benefit_sponsor_catalog.product_package_for(self)

        if new_product_package.present? && reference_product.present?
          if reference_product.renewal_product.present? && new_product_package.active_products.include?(reference_product.renewal_product)
            new_sponsored_benefit = self.class.new(attributes_for_renewal(new_benefit_package, new_product_package))
            renew_pricing_determinations(new_sponsored_benefit)
            new_sponsored_benefit
          end
        end
      end

      def attributes_for_renewal(new_benefit_package, new_product_package)
        {
          product_package_kind: product_package_kind,
          product_option_choice: product_option_choice,
          reference_product: reference_product.renewal_product,
          sponsor_contribution: sponsor_contribution.renew(new_product_package),
          benefit_package: new_benefit_package
        }
      end

      def renew_pricing_determinations(new_sponsored_benefit)
        cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(new_sponsored_benefit.benefit_sponsorship, new_sponsored_benefit.benefit_package.benefit_application.effective_period.min)
        _sbenefit, _price, _cont = cost_estimator.calculate(new_sponsored_benefit, new_sponsored_benefit.reference_product, new_sponsored_benefit.product_package, build_new_pricing_determination: true)
      end

      def reference_plan_id=(product_id)
        self.reference_product_id = product_id
      end

      def sponsor_contribution_attributes=(sponsor_contribution_attrs)
        # build_sponsor_contribution(sponsor_contribution_attrs)
      end

      def pricing_determinations=(pds_values)
        pds_values.each do |pd_value|
          if pd_value.is_a?(Hash)
            self.pricing_determinations.build(pd_value)
          else
            self.pricing_determinations.push(pd_value)
          end
        end
      end
    end
  end
end
