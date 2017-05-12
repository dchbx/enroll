module Aca
  module Shop
    # Busines rules for determining if sponsor organization may offer sponsored benefit
    class SponsorEligibleForBenefitPolicy

      def initialize(sponsor, markets, options = {})
        @sponsor = sponsor
        @markets = markets
      end

      def eligible_markets
        if @sponsor.parent.class_name.to_s == "EmployerProfile" 
        elsif @sponsor.parent.class_name.to_s == "Hbx" 
        else
        end
      end

      def is_eligible?(market)
        @scores = []
      end

    end
  end
end