module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorCatalogDecorator < SimpleDelegator

      Product = Struct.new(:id, :title, :metal_level_kind, :carrier_name, :issuer_id, :sole_source, :coverage_kind, :health_plan_kind, :network_information)
      ContributionLevel = Struct.new(:id, :display_name, :contribution_factor, :is_offered, :contribution_unit_id)

      def sponsor_contributions(benefit_package_id = nil)
        return @contributions if defined? @contributions

        if benefit_package_id.present?
          benefit_package = self.benefit_application.benefit_packages.detect{|bp| bp.id.to_s == benefit_package_id}
        end


        @contributions = product_packages.inject({}) do |contributions, product_package|
          
          if benefit_package.present?
            if sponsored_benefit = benefit_package.sponsored_benefits.detect{|sb| sb.product_package == product_package}
              sponsor_contribution = sponsored_benefit.sponsor_contribution
            end
          end

          if sponsor_contribution.blank?
            contribution_service = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
            sponsor_contribution = contribution_service.build_sponsor_contribution(product_package)
          end

          contributions[product_package.package_kind.to_s] = {
            id: nil,
            contribution_levels: sponsor_contribution.contribution_levels.collect{|cl| 
                     ContributionLevel.new(cl.id.to_s, cl.display_name, cl.contribution_factor, true, cl.contribution_unit_id)
                    }
          }

          contributions
        end
      end

      def plan_option_kinds
        plan_options.keys
      end

      def single_issuer_options
        carrier_name_and_id_hash = {}
        Hash[plan_options[:single_issuer].sort_by { |k, v| k }].each do |k, v|
          carrier_name_and_id_hash[k] = v.first["issuer_id"].to_s
        end
        carrier_name_and_id_hash
      end

      def metal_levels
        plan_options[:metal_level].keys
      end

      def single_product_options
        single_product_options_hash = {}
        Hash[plan_options[:single_product].sort_by { |k, v| k }].each do |k, v|
          single_product_options_hash[k] = v.first["issuer_id"].to_s
        end
        single_product_options_hash
      end

      def probation_period_kinds
        [
          ["First of the month following or coinciding with date of hire", 'first_of_month'], 
          ["First of the month following 30 days", 'first_of_month_after_30_days'], 
          ["First of the month following 60 days", 'first_of_month_after_60_days']
        ]
      end

      def plan_options
        return @products if defined? @products
        @products = {}

        product_packages.each do |product_package|
          package_products = product_package.products.collect do |product|
            Product.new(product.id, product.title, product.metal_level_kind, carriers[product.issuer_profile_id.to_s], product.issuer_profile_id, false, product.is_a?(BenefitMarkets::Products::HealthProducts::HealthProduct) ? "health" : "dental", product.health_plan_kind, product.network_information)
          end
          @products[product_package.package_kind] = case product_package.package_kind
            when :single_issuer
              package_products.group_by(&:carrier_name)
            when :metal_level
              package_products.group_by(&:metal_level_kind)
            else
              package_products.group_by(&:carrier_name)
            end
        end

        @products
      end

      def carriers
        return @carriers if defined? @carriers
        issuer_orgs = BenefitSponsors::Organizations::Organization.where(:"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile")
        @carriers = issuer_orgs.inject({}) do |issuer_hash, issuer_org|
          issuer_profile  = issuer_org.profiles.where(:"_type" => "BenefitSponsors::Organizations::IssuerProfile").first
          issuer_hash[issuer_profile.id.to_s] = issuer_org.legal_name
          issuer_hash
        end
      end

      def carrier_level_options
        plan_options.group_by(&:carrier_name)
      end

      def metal_level_options
        plan_options.group_by(&:metal_level_kind)
      end

      def single_plan_options
        plan_options
      end
    end
  end
end
