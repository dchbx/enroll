class BenefitEligibilityElementGroup
  include Mongoid::Document

  # whitelist approach

  embedded_in :benefit_package

  INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS = %w(
      self
      spouse
      domestic_partner
      child
      parent
      sibling
      ward
      guardian
      unrelated
      other_tax_dependent
      grandchild
      nephew_or_niece
    )

  SHOP_MARKET_RELATIONSHIP_CATEGORY_KINDS = %w(
      self
      spouse
      domestic_partner
      children_under_26
      disabled_children_26_and_over
      children_26_and_over
      nephew_or_niece
      grandchild
    )


  field :market_places,          type: Array, default: ["any"]   # %w[any shop individual],
  field :enrollment_periods,     type: Array, default: ["any"]   # %w[any open_enrollment special_enrollment],
  field :family_relationships,   type: Array, default: ["any"]   # %w[any self spouse domestic_partner child_under_26 child_26_and_over disabled_children_26_and_over],
  field :benefit_categories,     type: Array, default: ["any"]   # %w[health dental retirement disability],

  field :incarceration_status,   type: Array, default: ["any"]   # %w[any unincarcerated],
  field :age_range,              type: Range, default: 0..0
  field :citizenship_status,     type: Array, default: ["any"]   # %w[any us_citizen naturalized_citizen alien_lawfully_present lawful_permanent_resident],
  field :residency_status,       type: Array, default: ["any"]   # %w[any state_resident],
  field :ethnicity,              type: Array, default: ["any"]   # %w[any indian_tribe_member],
  field :cost_sharing,           type: String, default: ""
  field :lawful_presence_status, type: String, default: ""


  # validates :eligible_relationship_categories,
  #   allow_blank: false,
  #   inclusion: {
  #     in: ELIGIBLE_RELATIONSHIP_CATEGORY_KINDS,
  #     message: "%{value} is not a valid eligible relationship category kind"
  #   }

end
