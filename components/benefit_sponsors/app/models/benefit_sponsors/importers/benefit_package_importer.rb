module BenefitSponsors
  module Importers
    class BenefitPackageImporter

      # Service accepts following atttributes along with benefit application to this service. 
      # It would construct benefit_package along with sponsored_benefits.
      #
      # { :title, :description, :created_at, :updated_at, :is_active, :effective_on_kind, :effective_on_offset, :is_default, 
      #   :plan_option_kind, :reference_plan_hios_id, :relationship_benefits, :dental_reference_plan_hios_id, :dental_relationship_benefits 
      # }

      attr_accessor :benefit_package

      def self.call(benefit_application, args)
        self.new(benefit_application, args)
      end

      def initialize(benefit_application, args)
        @benefit_application = benefit_application
        @plan_option_kind    = args[:plan_option_kind].to_sym
        construct_benefit_package(args)
      end

      def construct_benefit_package(attributes)
        benefit_package = @benefit_application.benefit_packages.build(
          attributes.slice(:title, :description, :created_at, :updated_at, :is_active, :is_default)
        )
        benefit_package.probation_period_kind = probation_period_kind_for(attributes[:effective_on_kind], attributes[:effective_on_offset])
        construct_sponsored_benefit(benefit_package, filtered_attributes_for(attributes, :health))
        construct_sponsored_benefit(benefit_package, filtered_attributes_for(attributes, :dental)) if is_offering_dental?(attributes)
        @benefit_package = benefit_package
      end

      # TODO: Enhance this to handle Dental Sponsored Benefits
      def construct_sponsored_benefit(benefit_package, sponsored_benefit_attrs)
        if sponsored_benefit_attrs[:product_kind] == :health
          sponsored_benefit  = BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new
          sponsored_benefit.product_package_kind = map_product_package_kind(sponsored_benefit_attrs[:plan_option_kind])
          sponsored_benefit.benefit_package = benefit_package
        
          if sponsored_benefit.product_package.present?
            
            sponsored_benefit.reference_product = sponsored_benefit.product_package.products.where(hios_id: sponsored_benefit_attrs[:reference_plan_hios_id]).first
            raise StandardError, "Unable find reference product" if sponsored_benefit.reference_product.blank?
            sponsored_benefit.product_option_choice = product_package_choice_for(sponsored_benefit)
            if sole_source?
              sponsor_contribution_attrs = sponsored_benefit_attrs[:composite_tier_contributions]
            else
              sponsor_contribution_attrs = sponsored_benefit_attrs[:relationship_benefits]
            end

            build_sponsor_contribution(sponsored_benefit, sponsor_contribution_attrs)
            build_pricing_determinations(sponsored_benefit, sponsor_contribution_attrs) if sole_source?
          else
            raise StandardError, "Unable to map product_package for sponsored_benefit!!"
          end
        end
      end

      def build_sponsor_contribution(sponsored_benefit, sponsor_contribution_attrs)
        sponsored_benefit.sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)

        if sponsored_benefit.sponsor_contribution.blank?
          raise StandardError, "Sponsor Contribution construction failed!!"
        end

        sponsored_benefit.sponsor_contribution.contribution_levels.each do |new_contribution_level|
          contribution_match = sponsor_contribution_attrs.detect{|contribution| (((contribution[:relationship] == "child_under_26") ? "dependent" : contribution[:relationship]) == new_contribution_level.contribution_unit.name)}
          if contribution_match.present?
            new_contribution_level.is_offered = contribution_match[:offered]
            new_contribution_level.contribution_factor = (contribution_match[:premium_pct].to_f / 100)
          end
        end
      end

      def build_pricing_determinations(sponsored_benefit, sponsor_contribution_attrs)
        # estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(sponsored_benefit.benefit_sponsorship, sponsored_benefit.benefit_package.start_on)
        # estimator.calculate(sponsored_benefit, sponsored_benefit.reference_product, sponsored_benefit.product_package)

        pricing_model = sponsored_benefit.product_package.pricing_model

        price_determination_tiers = pricing_model.pricing_units.inject([]) do |pd_tiers, pricing_unit|
          pd_tiers << BenefitSponsors::SponsoredBenefits::PricingDeterminationTier.new(
            pricing_unit_id: pricing_unit.id
            )
        end
        
        sponsored_benefit.pricing_determinations.build(pricing_determination_tiers: price_determination_tiers)

        pricing_determination = sponsored_benefit.pricing_determinations.first

        if sponsor_contribution_attrs[0].present?
          if sponsor_contribution_attrs[0][:final_tier_premium].present?
            copy_tier_contributions(pricing_determination, sponsor_contribution_attrs, :final_tier_premium)
          else
            copy_tier_contributions(pricing_determination, sponsor_contribution_attrs, :estimated_tier_premium)
          end
        end
      end

      def copy_tier_contributions(pricing_determination, sponsor_contribution_attrs, attribute_to_copy)
        pricing_determination.pricing_determination_tiers.each do |tier|
          # During Migration, we are checking for composite_rating_tier field value
          matched_tier = sponsor_contribution_attrs.detect{ |tier_contribution| (tier_contribution[:relationship] ? tier_contribution[:relationship]: tier_contribution[:composite_rating_tier]) == tier.pricing_unit.name }
          tier.price = matched_tier[attribute_to_copy].to_f
        end
      end

      private

      def map_product_package_kind(plan_option_kind)
        package_kind_mapping = {
          sole_source: :single_product,
          single_plan: :single_product,
          single_carrier: :single_issuer,
          metal_level: :metal_level
        }

        package_kind_mapping[plan_option_kind.to_sym]
      end

      def product_package_choice_for(sponsored_benefit)
        case sponsored_benefit.product_package_kind
        when :single_product, :single_issuer
          sponsored_benefit.reference_product.issuer_profile.id
        when :metal_level
          sponsored_benefit.reference_product.metal_level_kind
        end
      end

      def probation_period_kind_for(effective_on_kind, effective_on_offset)
        if effective_on_kind == 'first_of_month'
          case effective_on_offset
          when 0
            :first_of_month
          when 30
            :first_of_month_after_30_days
          when 60
            :first_of_month_after_60_days
          end
        elsif effective_on_kind == 'date_of_hire'
          :date_of_hire
        end
      end

      def sole_source?
        @plan_option_kind == :sole_source
      end

      def is_offering_dental?(attributes)
        attributes[:dental_reference_plan_hios_id].present?
      end

      def filtered_attributes_for(attributes, product_kind)
        if product_kind == :health
          sponsored_benefit_attrs = attributes.slice(:plan_option_kind, :reference_plan_hios_id, (sole_source? ? :composite_tier_contributions : :relationship_benefits))
          sponsored_benefit_attrs[:product_kind] = :health
        elsif product_kind == :dental
          sponsored_benefit_attrs = attributes.slice(:dental_reference_plan_hios_id, :dental_relationship_benefits)
          sponsored_benefit_attrs[:product_kind] = :dental
        end

        sponsored_benefit_attrs
      end
    end
  end
end