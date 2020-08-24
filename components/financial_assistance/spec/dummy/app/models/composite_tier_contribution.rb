# frozen_string_literal: true

class CompositeTierContribution
  include Mongoid::Document

  embedded_in :benefit_group

  field :composite_rating_tier, type: String
  field :employer_contribution_percent, type: Float, default: 0.0
  field :estimated_tier_premium, type: Float, default: 0.0
  field :final_tier_premium, type: Float
  field :offered, type: Boolean, default: true
end
