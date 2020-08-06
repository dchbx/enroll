# frozen_string_literal: true

module BenefitSponsors
  module ContributionCalculators
    class ContributionCalculator

      # Calculate contributions for the given entry
      # @param contribution_model [BenefitMarkets::ContributionModel] the
      #   contribution model for this calculation
      # @param priced_roster_entry [BenefitMarkets::SponsoredBenefits::PricedRosterEntry]
      #   the roster entry for which to provide contribution
      # @param sponsor_contribution [BenefitSponsors::SponsoredBenefits::SponsorContribution]
      #   the concrete values for contributions
      # @return [BenefitMarkets::SponsoredBenefits::ContributionRosterEntry] the
      #   contribution results paired with the roster
      def calculate_contribution_for(_contribution_model, _priced_roster_entry, _sponsor_contribution)
        raise NotImplementedError, "subclass responsiblity"
      end
    end
  end
end
