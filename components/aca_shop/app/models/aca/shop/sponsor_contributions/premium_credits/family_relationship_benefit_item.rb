module Aca
  module Shop
    module SponsorContributions
      module PremiumCredits
        class FamilyRelationshipBenefitItem
          include Mongoid::Document

          # embedded_in :premium_credit, class_name: "Aca::Shop::SponsorContributions::PremiumCredits::AcaShopChoice"

          field :relationship, type: String
          field :offered, type: Boolean, default: true
          field :premium_pct, type: Float, default: 0.0
          field :employer_max_amt, type: Money

          validates_numericality_of :premium_pct, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0

          # Indicates whether employer offers coverage for this relationship
          alias_method :is_offered?, :is_offered

          def premium_pct=(new_premium_pct)
            self[:premium_pct] = new_premium_pct.blank? ? 0.0 : new_premium_pct.try(:to_f).try(:round)
          end

        end

      end
    end
  end
end