# frozen_string_literal: true

module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitFactory

      attr_accessor :package

      def self.call(package, args)
        new(package, args).sponsored_benefit
      end

      def self.validate(_sponsored_benefit)
        # TODO: Add validations if any
        true
      end

      def initialize(package, attrs)
        @package = package
        attrs[:id].present? ? update_sponsored_benefit(attrs) : initialize_sponsored_benefit(attrs)
      end

      def initialize_sponsored_benefit(attrs)
        @s_benefit = sponsored_benefit_class(attrs[:kind]).new(attrs.except(:sponsor_contribution_attributes))
        @s_benefit.benefit_package = package
        @s_benefit.sponsor_contribution = build_sponsor_contribution(@s_benefit, attrs[:sponsor_contribution_attributes])
        @s_benefit
      end

      def update_sponsored_benefit(attrs)
        @s_benefit = find_sponsored_benefit(attrs[:id])
        @s_benefit.assign_attributes(attrs.except(:sponsor_contribution_attributes))
        @s_benefit.sponsor_contribution = build_sponsor_contribution(sponsored_benefit, attrs[:sponsor_contribution_attributes])
        @s_benefit
      end

      def build_sponsor_contribution(sponsored_benefit, attrs)
        product_package = attrs[:product_package].present? ? attrs[:product_package] : sponsored_benefit.product_package
        sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(product_package)
        sponsor_contribution_attrs = []
        sponsor_contribution.contribution_levels.each do |new_contribution_level|
          sponsor_contribution_attrs = attrs[:contribution_levels_attributes] if attrs.present?

          next unless contribution_match = sponsor_contribution_attrs.detect{ |contribution| contribution[:display_name] == new_contribution_level.display_name}
          contribution_level_attr = contribution_match.except(:id, :display_name)
          contribution_level_attr[:is_offered] ||= false
          new_contribution_level.assign_attributes(contribution_level_attr)
        end

        sponsor_contribution
      end

      def sponsored_benefit_class(kind)
        "BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit".gsub("Health", kind.humanize).constantize
      end

      def sponsored_benefit
        @s_benefit
      end

      def find_sponsored_benefit(sponsored_benefit_id)
        return nil if sponsored_benefit_id.blank?
        package.sponsored_benefits.find(sponsored_benefit_id)
      end
    end
  end
end
