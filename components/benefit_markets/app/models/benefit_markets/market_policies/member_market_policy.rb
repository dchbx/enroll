module BenefitMarkets
  class MarketPolicies::MemberMarketPolicy < MarketPolicies::MarketPolicy

    # DC SHOP
      # Congress members
      # 'newly designated' bypass probation period

    # DC Individual
      # age-off 26, 65
      # catastrophic plans - enrollment group must be < 30
      ## See existing rules

    # CCA SHOP
      # access frozen plans if member enrolled in last year's mapped plan == true

    # GIC
      # must purchase life to purchase health

    field :age_range_policy,              type: Range,   default: 0..0
    field :child_age_off_policy,          type: Integer, default: 26
    field :incarceration_status_policy,   type: Array,   default: [ :any ]   # => [:any, :unincarcerated],
    field :citizenship_status_policy,     type: Array,   default: [ :any ]   # => [:any, :us_citizen :naturalized_citizen :alien_lawfully_present :lawful_permanent_resident]
    field :residency_status_policy,       type: Array,   default: [ :any ]   # => [:any, :state_resident],
    field :ethnicity_policy,              type: Array,   default: [ :any ]   # => [:any, :indian_tribe_member]

    field :product_dependencies_policy,   type: Array,   default: [ :any ]   # => DC SHOP: must purchase health to purchase dental { dental: [ :health ] }

    field :cost_sharing_policy,           type: String,  default: ""
    field :lawful_presence_status_policy, type: String,  default: ""

  end
end
