module BenefitMarkets
  module ContributionModels
    class FixedPercentContributionUnit < ContributionUnit
      include Mongoid::Document

      field :default_contribution_factor, type: Float
      field :minimum_contribution_factor, type: Float, default: 0.0

      validates_numericality_of :default_contribution_factor, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0, allow_nil: false
      validates_numericality_of :minimum_contribution_factor, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0, allow_nil: false

      def assign_contribution_value_defaults(cv)
        super(cv)
        cv.contribution_factor = default_contribution_factor
        cv.min_contribution_factor = default_contribution_factor
      end
    end
  end
end
