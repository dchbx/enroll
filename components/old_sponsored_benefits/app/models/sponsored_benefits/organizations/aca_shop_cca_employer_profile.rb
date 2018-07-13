module SponsoredBenefits
  module Organizations
    class AcaShopCcaEmployerProfile < Profile
      include Concerns::AcaRatingAreaConfigConcern
      
      field  :sic_code, type: String
      embeds_one  :employer_attestation
      embedded_in :plan_design_proposal, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal"

      after_initialize :initialize_benefit_sponsorship

      def primary_office_location
        (organization || plan_design_organization).primary_office_location
      end

      def rating_area
        if use_simple_employer_calculation_model?
          return nil
        end
        RatingArea.rating_area_for(primary_office_location.address)
      end

      def service_areas
        if use_simple_employer_calculation_model?
          return nil
        end
        CarrierServiceArea.service_areas_for(office_location: primary_office_location)
      end

      def service_areas_available_on(date)
        if use_simple_employer_calculation_model?
          return []
        end
        CarrierServiceArea.service_areas_available_on(primary_office_location.address, date.year)
      end

      def service_area_ids
        if use_simple_employer_calculation_model?
          return nil
        end
        service_areas.collect { |service_area| service_area.service_area_id }.uniq
      end

    private

      def initialize_benefit_sponsorship
        benefit_sponsorships.build(benefit_market: :aca_shop_cca, enrollment_frequency: :rolling_month) if benefit_sponsorships.blank?
      end
    end
  end
end
