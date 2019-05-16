 # frozen_string_literal: true

module Notifier
  module MergeDataModels
    class SponsoredBenefit
      include Virtus.model

      attribute :product_kind, String
      attribute :product_package_kind, String
      attribute :reference_product_name, String
      attribute :reference_product_carrier_name, String
      attribute :plan_offerings_text, String
      attribute :sponsor_contribution, MergeDataModels::SponsorContribution

      def self.stubbed_object
        sponsored_benefit = Notifier::MergeDataModels::SponsoredBenefit.new({product_kind: 'Health',
                                                                             product_package_kind: 'single_plan',
                                                                             plan_offerings_text: 'Gold Metal Level',
                                                                             reference_product_name: 'Blue Cross Blue Shieldd HMO',
                                                                             reference_product_carrier_name: 'BCBS'})

        sponsored_benefit.sponsor_contribution = Notifier::MergeDataModels::SponsorContribution.stubbed_object
        sponsored_benefit
      end
    end
  end
end
