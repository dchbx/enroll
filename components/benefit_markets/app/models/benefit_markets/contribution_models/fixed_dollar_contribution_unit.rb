module BenefitMarkets
  module ContributionModels
    class FixedDollarContributionUnit < ContributionUnit
      include Mongoid::Document

      field :default_contribution_amount, type: Float

      validates_numericality_of :default_contribution_amount, greater_than_or_equal_to: 0.00, allow_nil: false

      def assign_contribution_value_defaults(cv)
        super(cv)
        cv.contribution_amount = default_contribution_amount
      end
    end
  end
end
