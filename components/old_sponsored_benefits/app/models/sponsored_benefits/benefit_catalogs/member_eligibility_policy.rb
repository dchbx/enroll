# Product dependencies and eligibility rules applied to enrolling members
module SponsoredBenefits
  module BenefitCatalogs
    class MemberEligibilityPolicy
      include Mongoid::Document
      include Mongoid::Timestamps

      field :age_range,               type: Range,      default: 0..0
      field :child_age_off,           type: Integer,    default: 26
      field :incarceration_status,    type: Array,      default: [ :any ]   # => [:any, :unincarcerated],
      field :citizenship_status,      type: Array,      default: [ :any ]   # => [:any, :us_citizen :naturalized_citizen :alien_lawfully_present :lawful_permanent_resident]
      field :residency_status,        type: Array,      default: [ :any ]   # => [:any, :state_resident],
      field :ethnicity,               type: Array,      default: [ :any ]   # => [:any, :indian_tribe_member]

      field :product_dependencies,    type: Array,      default: [ :any ]   # => DC SHOP: must purchase health to purchase dental { dental: [ :health ] }

      field :cost_sharing,            type: String,     default: ""
      field :lawful_presence_status,  type: String,     default: ""

      # DC Individual
      # age-off 26, 65
      # catastrophic plans - enrollment group must be < 30
      ## See existing rules

      # CCA SHOP
      # access frozen plans if member enrolled in last year's mapped plan == true

      # GIC 
      # must purchase life to purchase health

    end
  end
end
