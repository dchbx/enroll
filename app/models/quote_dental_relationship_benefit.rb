class QuoteDentalRelationshipBenefit
  include Mongoid::Document

  embedded_in :quote_benefit_group

  field :relationship, type: String
  field :premium_pct, type: Float, default: 0.0
  field :employer_max_amt, type: Money
  field :offered, type: Boolean, default: true

  # Indicates whether employer offers coverage for this relationship
  def offered?
    self.offered
  end

  def premium_pct=(new_premium_pct)
    self[:premium_pct] = new_premium_pct.blank? ? 0.0 : new_premium_pct.try(:to_f).try(:round)
  end

  validates_numericality_of :premium_pct, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0
end
