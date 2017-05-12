module Aca
  module Shop
    # Service class for renewing employer sponsored benefit
    class BenefitApplicationRenewer

      def initialize(employer_profile, benefit_kind, renewal_date)
        @employer_profile = employer_profile
        @benefit_kind     = benefit_kind
        @renewal_date     = renewal_date
      end

      def terminate
        return false unless @employer_profile && @benefit_kind && @renewal_date
      end

    end
  end
end