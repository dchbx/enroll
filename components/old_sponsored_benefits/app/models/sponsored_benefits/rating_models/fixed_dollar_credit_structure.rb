module SponsoredBenefits
  module RatingModels
    class FixedDollarCreditStructure < CreditStructure
      include Mongoid::Document
      include Mongoid::Timestamps

      field :contribution_amount_minimum, type: Money

      validate :contribution_amount_minimum,
                allow_nil: false


    end
  end
end
