class Translation
  include Mongoid::Document
  field :key, type: String
  field :value, type: String

  validates_uniqueness_of :key
end
