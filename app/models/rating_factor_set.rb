class RatingFactorSet
  include Mongoid::Document
  include MongoidSupport::AssociationProxies

  associated_with_one :carrier_profile, :carrier_profile_id, "CarrierProfile"

  field :active_year, type: Integer
  field :default_factor_value, type: Float
  field :carrier_profile_id, type: BSON::ObjectId

  field :max_integer_factor_key, type: Integer

  embeds_many :rating_factor_entries

  validates_presence_of :carrier_profile_id, :allow_blank => false
  validates_numericality_of :default_factor_value, :allow_blank => false
  validates_numericality_of :active_year, :allow_blank => false

  def lookup(key)
    entry = rating_factor_entries.detect { |rfe| rfe.factor_key == key }
    entry.nil? ? default_factor_value : entry.factor_value
  end
end
