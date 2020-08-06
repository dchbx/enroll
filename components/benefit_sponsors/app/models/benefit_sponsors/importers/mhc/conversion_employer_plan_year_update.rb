# frozen_string_literal: true

module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYearUpdate < ConversionEmployerPlanYear

      def save
        return false unless self.valid?
        return false if sponsored_benefit_kind == :health

        # TODO: health sponsored update needs to be implemented. currently plan year update only works for dental.
        benefit_package = find_benefit_package
        sponsored_benefit = BenefitSponsors::SponsoredBenefits::SponsoredBenefitFactory.call(benefit_package, sanitized_sponsored_benefit_params)
        sponsored_benefit.source_kind = :conversion
        sponsored_benefit.reference_plan_id = find_product.id
        return true if sponsored_benefit.save
      end

      def sanitized_sponsored_benefit_params
        {
          :kind => "dental",
          :product_option_choice => find_carrier.id,
          :product_package_kind => "single_product",
          :sponsor_contribution_attributes =>
                {:product_package => build_dental_product_package,
                 :contribution_levels_attributes => formed_params_for_contribution_levels}
        }
      end

      def build_dental_product_package
        # this line should go away once 2019 dental product packages introduced
        application_period = {:min => Time.new(2018,0o1,0o1).utc, :max => Time.new(2018,12,31).utc}
        product_package = BenefitMarkets::Products::ProductPackage.new(benefit_kind: :aca_shop,
                                                                       product_kind: :dental,
                                                                       application_period: application_period,
                                                                       package_kind: :single_product,
                                                                       title: "Single Product",
                                                                       description: "")
        product_package.contribution_model = BenefitMarkets::ContributionModels::ContributionModel.where(title: "MA Shop Simple List Bill Contribution Model").first.create_copy_for_embedding
        product_package
      end

      def formed_params_for_contribution_levels
        contribution_levels = []
        dental_tiers = formed_dental_tier_contribution_levels
        dental_tiers.each do |contribution_level|
          relation = contribution_level[:relationship]
          contribution_name = relation_ship_mapping[relation]
          contribution_factor = contribution_level[:premium_pct].to_f / 100
          contribution_levels.push({:display_name => contribution_name, :contribution_factor => contribution_factor, :is_offered => true})
        end
        contribution_levels
      end

      def formed_dental_tier_contribution_levels
        contribution_level_names = [
            "employee_only",
            "employee_and_spouse",
            "employer_domestic_partner",
            "employer_child_under_26"
        ]
        contribution_level_names.inject([]) do |contributions, sponsor_level_name|
          contributions << {
            relationship: sponsor_level_name,
            premium_pct: eval("#{sponsor_level_name}_rt_contribution")
          }
        end
      end

      def relation_ship_mapping
        {
          "employee_only" => "Employee",
          "employee_and_spouse" => "Spouse",
          "employer_domestic_partner" => "Domestic Partner",
          "employer_child_under_26" => "Child Under 26"
        }
      end
    end
  end
end
