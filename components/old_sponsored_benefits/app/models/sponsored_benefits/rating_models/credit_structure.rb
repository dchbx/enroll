module SponsoredBenefits
  module RatingModels
    class CreditStructure
      include Mongoid::Document
      include Mongoid::Timestamps

      KINDS = [ 
                :percent_with_cap,                  # Congress
                :reference_plan_percent,            # DC SHOP list bill
                :group_composite_percent,           # MA SHOP
                :fixed_dollar_only,                 # DC Individual financial assistance
                :reference_plan_percent_with_cap,  
                :percent_only, 
              ]

      embedded_in :rating_tier, class_name: "SponsoredBenefits::RatingModels::RatingTier"

    end
  end
end
