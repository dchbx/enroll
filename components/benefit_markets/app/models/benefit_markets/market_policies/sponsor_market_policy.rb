module BenefitMarkets
  class MarketPolicies::SponsorMarketPolicy < MarketPolicies::MarketPolicy

    # Count of primary members necessary for sponsor eligibility
    field :roster_size_rule,              type: Range,    default: 0..0
    field :full_time_employee_size_rule,  type: Range,    default: 0..0
    field :part_time_employee_size_rule,  type: Range,    default: 0..0

    field :rostered_non_owner_size_rule,  type: Integer,  default: 0
    field :benefit_categories,            type: Array,    default: [ :any ]

    # CCA SHOP
    # access frozen plans if number of members enrolled in last year's mapped plan > 0


    def set_aca_shop_defaults
      # ACA SHOP: 0 < roster size < 50
      roster_size = 1..50

      # ACA SHOP: roster member non-owner > 0
      rostered_non_owner_size = 1
    end

  end
end
