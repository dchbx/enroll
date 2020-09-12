# frozen_string_literal: true

class CompositeRatingTierFactorSet < RatingFactorSet
  validate :only_valid_tier_names

  def self.value_for(carrier_profile_id, year, val)
    record = self.where(carrier_profile_id: carrier_profile_id, active_year: year).first
    if record.present?
      record.lookup(val)
    else
      logger.error "Lookup for #{val} failed with no FactorSet found: Carrier: #{carrier_profile_id}, Year: #{year}"
      1.0
    end
  end

  def only_valid_tier_names
    invalid_entries = rating_factor_entries.any? do |rfe|
      !CompositeRatingTier::NAMES.include?(rfe.factor_key)
    end
    errors.add(:rating_factor_entries, "Contain invalid tier names.") if invalid_entries
  end
end
