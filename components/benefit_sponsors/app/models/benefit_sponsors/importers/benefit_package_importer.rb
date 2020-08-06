# frozen_string_literal: true

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
        sponsored_benefit = if sponsored_benefit_attrs[:product_kind] == :health
                              BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new
                            else
                              BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new
                            end

        package_kind = sponsored_benefit_attrs[:product_kind] == :dental && sponsored_benefit_attrs[:plan_option_kind] == "single_plan" ? :multi_product : map_product_package_kind(sponsored_benefit_attrs[:plan_option_kind])
        sponsored_benefit.product_package_kind = package_kind
        sponsored_benefit.benefit_package = benefit_package

        if sponsored_benefit.product_package.present?
          sponsored_benefit.reference_product = sponsored_benefit.product_package.products.where(hios_id: sponsored_benefit_attrs[:reference_plan_hios_id]).first
          raise StandardError, "Unable find reference product" if sponsored_benefit.reference_product.blank?
          sponsored_benefit.product_option_choice = product_package_choice_for(sponsored_benefit)

          sponsor_contribution_attrs = if sole_source? && sponsored_benefit_attrs[:product_kind] == :health
                                         sponsored_benefit_attrs[:composite_tier_contributions]
                                       else
                                         sponsored_benefit_attrs[:relationship_benefits]
                                       end

          if sponsored_benefit_attrs[:product_kind] == :dental && sponsored_benefit.product_package_kind == :multi_product
            sponsored_benefit.elected_product_choices = sponsored_benefit.product_package.products.where(:hios_id => {"$in" => sponsored_benefit_attrs[:elected_dental_plan_hios_ids]}).map(&:_id)
          end

          build_sponsor_contribution(sponsored_benefit, sponsor_contribution_attrs)
          build_pricing_determinations(sponsored_benefit, sponsor_contribution_attrs) if sole_source? && sponsored_benefit_attrs[:product_kind] == :health
        else
          raise StandardError, "Unable to map product_package for sponsored_benefit!!"
        end
      end

      def build_sponsor_contribution(sponsored_benefit, sponsor_contribution_attrs)
        sponsored_benefit.sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)

        raise StandardError, "Sponsor Contribution construction failed!!" if sponsored_benefit.sponsor_contribution.blank?

        sponsored_benefit.sponsor_contribution.contribution_levels.each do |new_contribution_level|
          profile = @benefit_application.sponsor_profile
          if profile._type == "BenefitSponsors::Organizations::FehbEmployerProfile"
            # For congress, all contributions are offered and contribution percent 75%
            new_contribution_level.is_offered = true
            new_contribution_level.contribution_factor = 0.75
            new_contribution_level.contribution_cap = congress_contribution_cap(new_contribution_level.contribution_unit.name, @benefit_application.start_on.year)
          else
            contribution_match = sponsor_contribution_attrs.detect{|contribution| ((contribution[:relationship] == "child_under_26" ? "dependent" : contribution[:relationship]) == new_contribution_level.contribution_unit.name)}
            if contribution_match.present?
              new_contribution_level.is_offered = contribution_match[:offered]
              new_contribution_level.contribution_factor = (contribution_match[:premium_pct].to_f / 100)
            end
          end
        end
      end

      def congress_contribution_cap(unit_name, calender_year)
        # set contribution_cap for congress
        default_cont_cap = {2014 => {employee_only: 0.0, employee_plus_one: 0.0, family: 0.0},
                            2015 => {employee_only: 437.69, employee_plus_one: 971.90, family: 971.90},
                            2016 => {employee_only: 462.3, employee_plus_one: 998.88, family: 1058.42},
                            2017 => {employee_only: 480.29, employee_plus_one: 1030.88, family: 1094.64},
                            2018 => {employee_only: 496.71, employee_plus_one: 1063.83, family: 1130.09},
                            2019 => {employee_only: 498.72, employee_plus_one: 1066.59, family: 1138.19}}
        default_cont_cap[calender_year][unit_name.to_sym]
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
          matched_tier = sponsor_contribution_attrs.detect{ |tier_contribution| (tier_contribution[:relationship] || tier_contribution[:composite_rating_tier]) == tier.pricing_unit.name }
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
          sponsored_benefit.reference_product.issuer_profile.id if sponsored_benefit.reference_product.issuer_profile.present?
        when :metal_level
          sponsored_benefit.reference_product.metal_level_kind
        end
      end

      def probation_period_kind_for(effective_on_kind, effective_on_offset)
        if effective_on_kind == 'first_of_month'
          case effective_on_offset
          when 0
            :first_of_month
          when 1
            :first_of_month_following
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
          sponsored_benefit_attrs = {
            product_kind: :dental,
            plan_option_kind: attributes[:dental_plan_option_kind],
            reference_plan_hios_id: attributes[:dental_reference_plan_hios_id],
            relationship_benefits: attributes[:dental_relationship_benefits],
            elected_dental_plan_hios_ids: attributes[:elected_dental_plan_hios_ids]
          }
        end

        sponsored_benefit_attrs
      end
    end
  end
end