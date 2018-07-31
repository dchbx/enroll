class EmployerParticipationRateRatingFactorSet < RatingFactorSet
  def self.value_for(carrier_profile_id, year, val)
    record = self.where(carrier_profile_id: carrier_profile_id, active_year: year).first
    record.lookup(val)
  end

  # Expects a number out of 100, NOT a fraction.
  # 97.1234 is OK, 0.971234 is NOT
  def lookup(val)
    rounded_value = val.respond_to?(:round) ? val.round : val
    transformed_value = (rounded_value < 1) ? 1 : rounded_value
    super(transformed_value.to_s)
  end
end
