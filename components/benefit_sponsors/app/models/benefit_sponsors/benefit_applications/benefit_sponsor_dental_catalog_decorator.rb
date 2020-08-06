# frozen_string_literal: true

module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorDentalCatalogDecorator < SimpleDelegator

      Product = Struct.new(:id, :title, :metal_level_kind, :carrier_name, :issuer_id, :sole_source, :coverage_kind, :product_type, :network_information, :network)
      ContributionLevel = Struct.new(:id, :display_name, :contribution_factor, :is_offered, :contribution_unit_id) do
        def persisted?
          false
        end

        def is_employee_cl
          display_name == "Employee" || display_name == "Employee Only"
        end
      end
      SponsorContribution = Struct.new(:package_kind, :contribution_levels) do
        def persisted?
          false
        end

        def contribution_levels_attributes=(val); end
      end


      def sponsor_contributions(benefit_package_id = nil)
        return @contributions if defined? @contributions

        benefit_package = self.benefit_application.benefit_packages.detect{|bp| bp.id.to_s == benefit_package_id} if benefit_package_id.present?


        @contributions = product_packages.by_product_kind(:dental).inject({}) do |contributions, product_package|

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
            contribution_levels: sponsor_contribution.contribution_levels.collect do |cl|
              ContributionLevel.new(cl.id.to_s, cl.display_name, cl.contribution_factor, true, cl.contribution_unit_id)
            end
          }

          contributions
        end
      end

      # def sponsor_contributions(benefit_package_id = nil)
      #   return @contributions if defined? @contributions

      #   if benefit_package_id.present?
      #     benefit_package = self.benefit_application.benefit_packages.detect{|bp| bp.id.to_s == benefit_package_id}
      #   end


      #   @contributions = product_packages.by_product_kind(:dental).inject([]) do |contributions, product_package|
      #     if benefit_package.present?
      #       if sponsored_benefit = benefit_package.sponsored_benefits.detect{|sb| sb.product_package == product_package}
      #         sponsor_contribution = sponsored_benefit.sponsor_contribution
      #       end
      #     end

      #     if sponsor_contribution.blank?
      #       contribution_service = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
      #       sponsor_contribution = contribution_service.build_sponsor_contribution(product_package)
      #     end

      #     contributions << SponsorContribution.new(product_package.package_kind.to_s,
      #       sponsor_contribution.contribution_levels.collect { |cl|
      #         ContributionLevel.new(cl.id.to_s, cl.display_name, cl.contribution_factor, true, cl.contribution_unit_id)
      #       }
      #     )

      #     contributions
      #   end
      # end

      def plan_option_kinds
        plan_options.keys
      end

      def plan_options_for(option_kind)
        if option_kind == :multi_product
          plan_options[option_kind].inject({}) do |data, product|
            data[product.id.to_s] = product
            data
          end
        else
          Hash[plan_options[option_kind].sort_by { |carrier_name, _products| carrier_name }].inject({}) do |data, (_carrier_name, products)|
            data[products[0]["issuer_id"].to_s] = products[0]
            data
          end
        end
      end

      # def single_issuer_options
      #   carrier_name_and_id_hash = {}
      #   Hash[plan_options[:single_issuer].sort_by { |k, v| k }].each do |k, v|
      #     carrier_name_and_id_hash[k] = v.first["issuer_id"].to_s
      #   end
      #   carrier_name_and_id_hash
      # end

      # def single_product_options
      #   single_product_options_hash = {}
      #   Hash[plan_options[:single_product].sort_by { |k, v| k }].each do |k, v|
      #     single_product_options_hash[k] = v.first["issuer_id"].to_s
      #   end
      #   single_product_options_hash
      # end

      def plan_options
        return @products if defined? @products
        @products = {}

        product_packages.by_product_kind(:dental).each do |product_package|
          package_products = product_package.products.collect do |product|
            # TODO
            Product.new(product.id, product.title, product.metal_level, carriers[product.issuer_profile_id.to_s], product.issuer_profile_id, false, product.kind.to_s, product.product_type, product.network_information, product.network)
          end
          @products[product_package.package_kind] = case product_package.package_kind
                                                    when :multi_product
                                                      package_products
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
          issuer_profile = issuer_org.profiles.where(:_type => "BenefitSponsors::Organizations::IssuerProfile").first
          issuer_hash[issuer_profile.id.to_s] = issuer_org.legal_name
          issuer_hash
        end
      end

      def carrier_level_options
        plan_options.group_by(&:carrier_name)
      end

      def single_plan_options
        plan_options
      end
    end
  end
end
