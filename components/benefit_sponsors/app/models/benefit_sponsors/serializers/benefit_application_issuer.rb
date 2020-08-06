# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class BenefitApplicationIssuer
      # employer_hbx_id,employer_feinlan_year_startlan_year_end,carrier_hbx_id,carrier_fein
      def self.to_csv(benefit_application)
        benefit_application.benefit_packages.inject([]) do |list, benefit_package|
          benefit_package.sponsored_benefits.each do |sponsored_benefit|
            sponsored_benefit.products(benefit_application.start_on).each do |product|
              list.push [benefit_application.benefit_sponsorship.organization.hbx_id,
                         benefit_application.benefit_sponsorship.organization.fein,
                         benefit_application.effective_period.min.to_date.strftime('%Y-%m-%d'),
                         benefit_application.effective_period.max.to_date.strftime('%Y-%m-%d'),
                         product.issuer_profile.hbx_carrier_id,
                         product.issuer_profile.fein].join(',')
            end
          end
          list
        end.flatten
      end
    end
  end
end
