# frozen_string_literal: true

module BenefitSponsors
  module Importers
    module ConversionEmployerEmployeeLookUp
      def find_carrier
        BenefitSponsors::Organizations::IssuerProfile.find_by_abbrev(carrier)
      end

      def find_employer
        org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        return nil unless org
        org.profiles.first
      end

      def find_benefit_package
        employer_profile = find_employer
        benefit_application = employer_profile.active_benefit_application
        benefit_application.benefit_packages.first
      end

      # this method only used for adding dental product
      # TODO: Consdier all possible sceanrios like adding new benefit application for conversion and mid_year_conversion
      def find_product
        return nil if single_plan_hios_id.blank?

        benefit_application = find_employer.active_benefit_application
        period = benefit_application.effective_period

        clean_hios = single_plan_hios_id.split("-")[0]
        # corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
        BenefitMarkets::Products::Product.dental_products.where(hios_id: clean_hios).detect do |product|
          product.application_period.cover?(period.min)
        end
      end
    end
  end
end