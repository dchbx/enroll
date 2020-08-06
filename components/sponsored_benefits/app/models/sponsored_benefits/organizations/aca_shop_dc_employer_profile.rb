# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile

      field :profile_source, type: String, default: "broker_quote"
      field :contact_method, type: String, default: "Only Electronic communications"

      embeds_one :general_agency_profile, cascade_callbacks: true, validate: true
      embedded_in :plan_design_proposal, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal"

      after_initialize :initialize_benefit_sponsorship

      private

      def initialize_benefit_sponsorship
        benefit_sponsorships.build(benefit_market: :aca_shop_dc, enrollment_frequency: :rolling_month) if benefit_sponsorships.blank?
      end

    end
  end
end
