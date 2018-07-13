module SponsoredBenefits
  module RatingModels
    class GroupCompositePercentCreditStructure < CreditStructure
      include Mongoid::Document
      include Mongoid::Timestamps

      field :composite_tier_price,          type: Money
      field :contribution_percent_minimum,  type: Integer

      validate :contribution_percent_minimum,
                numericality: {only_integer: true, inclusion: 0..100},
                allow_nil: false

    end
  end
end
