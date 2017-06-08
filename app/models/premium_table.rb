class PremiumTable
  include Mongoid::Document

  embedded_in :plan

  field :age, type: Integer
  field :start_on, type: Date
  field :end_on, type: Date
  field :cost, type: Float
  field :rating_area, type: String

  validates_presence_of :age, :start_on, :end_on, :cost

end
