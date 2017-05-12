module Aca
  module Shop
    # Organization authority to offer a set of benefits 
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :employer_profile, class_name: "Aca::Shop::EmployerProfile"

      embeds_many :broker_agency_accounts, class_name: "::BrokerAgencyAccount"
      embeds_many :benefit_applications, class_name: "Aca::Shop::BenefitApplication"

      def eligible_benefits
        Aca::Shop::SponsorEligibleForBenefitPolicy.new(self).eligible_markets
      end

    end
  end
end