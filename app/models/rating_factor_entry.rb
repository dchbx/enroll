class RatingFactorEntry
  include Mongoid::Document

  embedded_in :rating_factor_set

  field :factor_key, type: String
  field :factor_value, type: Float

  validates_numericality_of :factor_value, :allow_blank => false
  validates_presence_of :factor_key, :allow_blank => false
end
