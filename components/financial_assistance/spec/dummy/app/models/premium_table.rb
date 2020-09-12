# frozen_string_literal: true

class PremiumTable
  include Mongoid::Document
  include Mongoid::Timestamps
  include Config::AcaModelConcern

  embedded_in :plan

  field :age, type: Integer
  field :start_on, type: Date
  field :end_on, type: Date
  field :cost, type: Float
  field :rating_area, type: String
end
