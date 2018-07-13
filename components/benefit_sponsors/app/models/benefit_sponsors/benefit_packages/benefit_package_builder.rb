module BenefitSponsors
  module BenefitPackages
    class BenefitPackageBuilder

      attr_reader :benefit_package, :benefit_package_attrs

      def initialize
        @benefit_package = BenefitSponsors::BenefitSponsorships::BenefitPackage.new
      end

      def self.build
        builder = new
        yield(builder)
        builder.build_benefit_package
        builder.benefit_package
      end

      def build_benefit_package
        add_title
        add_description
        add_effective_on_kind
        add_effective_on_offset
        add_plan_option_kind
        add_reference_plan
        # add_relationship_benefits
      end

      def effective_date(effective_date)
        @effective_date = effective_date
      end

      def benefit_sponsorship(benefit_sponsorship)
        @benefit_sponsorship = benefit_sponsorship
      end

      def benefit_market
        @benefit_sponsorship.benefit_market
      end

      def benefit_catalog
        return @benefit_catalog if defined? @benefit_catalog
        @benefit_catalog = benefit_market.benefit_catalog_by_effective_date(effective_date)
      end

      def benefit_package_options(options)
        @benefit_package_attrs = options.symbolize_keys
      end
        
      def add_title
        @benefit_package.title = benefit_package_attrs[:title]
      end

      def add_description
        @benefit_package.description = benefit_package_attrs[:description]
      end

      def add_effective_on_kind
        @benefit_package.effective_on_kind = benefit_package_attrs[:effective_on_kind]
      end

      def add_effective_on_offset
        @benefit_package.effective_on_offset = benefit_package_attrs[:effective_on_offset]
      end

      def add_plan_option_kind
        @benefit_package.plan_option_kind = benefit_package_attrs[:plan_option_kind]
      end

      def add_reference_plan
        @benefit_package.reference_plan_id = benefit_package_attrs[:reference_plan_id]
      end

      def add_relationship_benefits
      end

      def benefit_package
        @benefit_package
      end
    end

    class BenefitPackageBuilderError < StandardError; end
  end
end
