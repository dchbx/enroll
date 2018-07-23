class PremiumTable
  include Mongoid::Document
  include Config::AcaModelConcern

  embedded_in :plan

  field :age, type: Integer
  field :start_on, type: Date
  field :end_on, type: Date
  field :cost, type: Float
  field :rating_area, type: String

  validates_presence_of :age, :start_on, :end_on, :cost

  validates_inclusion_of :rating_area, :in => market_rating_areas, :allow_nil => true

end
