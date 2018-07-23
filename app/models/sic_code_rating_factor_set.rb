class SicCodeRatingFactorSet < RatingFactorSet
  def self.value_for(carrier_profile_id, year, val)
    record = self.where(carrier_profile_id: carrier_profile_id, active_year: year).first
    record.lookup(val)
  end
end
