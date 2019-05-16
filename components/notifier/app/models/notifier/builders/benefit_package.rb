# frozen_string_literal: true

module Notifier
  module Builders
    module BenefitPackage
      include ActionView::Helpers::NumberHelper

      def benefit_packages
        benefit_packages = load_benefit_application.benefit_packages
        merge_model.benefit_packages = build_benefit_packages(benefit_packages)
      end

      def build_benefit_packages(benefit_packages)
        benefit_packages.collect do |benefit_package|
          b_package = Notifier::MergeDataModels::BenefitPackage.new
          b_package.start_on = benefit_package.start_on
          b_package.title = benefit_package.title.titleize
          b_package.sponsored_benefits = build_sponsored_benenfits(benefit_package.sponsored_benefits)
          b_package
        end
      end

      def build_sponsored_benenfits(sponsored_benefits)
        sponsored_benefits.collect do |sponsored_benefit|
          s_benefit = Notifier::MergeDataModels::SponsoredBenefit.new
          s_benefit.product_kind = sponsored_benefit.health? ? 'health' : 'dental'
          s_benefit.product_package_kind = sponsored_benefit.product_package_kind
          s_benefit.reference_product_name = sponsored_benefit.reference_product.title.titleize
          s_benefit.reference_product_carrier_name = sponsored_benefit.reference_product.issuer_profile.legal_name.titleize
          s_benefit.plan_offerings_text = plan_offerings_text(sponsored_benefit)
          s_benefit.sponsor_contribution = build_sponsor_contribution(sponsored_benefit.sponsor_contribution)
          s_benefit
        end
      end

      def build_sponsor_contribution(sponsor_contribution)
        s_contribution = Notifier::MergeDataModels::SponsorContribution.new
        s_contribution.contribution_levels = build_contribution_levels(sponsor_contribution.contribution_levels)
        s_contribution
      end

      def plan_offerings_text(sponsored_benefit)
        case sponsored_benefit.product_package_kind
        when "single_carrier"
          "All plans from #{sponsored_benefit.reference_product.issuer_profile.legal_name.titleize}"
        when "metal_level"
          "#{sponsored_benefit.reference_product.metal_level.titleize} metal level"
        when "single_plan"
          "#{sponsored_benefit.reference_product.issuer_profile.legal_name.titleize} - #{sponsored_benefit.reference_product.title.titleize}"
        end
      end

      def build_contribution_levels(contribution_levels)
        contribution_levels.reject{ |con_lev| con_lev.display_name == 'child_26_and_over' }.collect do |contribution_level|
          c_levels = Notifier::MergeDataModels::ContributionLevel.new
          c_levels.display_name = contribution_level.display_name.titleize
          c_levels.contribution_pct = number_to_percentage(contribution_level.contribution_pct, precision: 0)
          c_levels
        end
      end
    end
  end
end
