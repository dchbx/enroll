class MigrateMaEmployerGroupSizeFactorSet < Mongoid::Migration
  def self.up
    old_carrier_profile_map = {}
    CarrierProfile.all.each do |cpo|
      old_carrier_profile_map[cpo.id] = cpo.hbx_id
    end

    new_carrier_profile_map = {}
    ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |ipo|
      i_profile = ipo.issuer_profile
      new_carrier_profile_map[ipo.hbx_id] = i_profile.id
    end

    EmployerGroupSizeRatingFactorSet.all.each do |rfs|
      factor_entries = rfs.rating_factor_entries.map do |rfe|
        ::BenefitMarkets::Products::ActuarialFactors::ActuarialFactorEntry.new(
          factor_key: rfe.factor_key,
          factor_value: rfe.factor_value
        ) 
      end
      ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.create!(
        active_year: rfs.active_year,
        default_factor_value: rfs.default_factor_value,
        max_integer_factor_key: rfs.max_integer_factor_key,
        issuer_profile_id: new_carrier_profile_map[old_carrier_profile_map[rfs.carrier_profile_id]],
        actuarial_factor_entries: factor_entries
      )
    end
  end

  def self.down
    raise "Can not be reversed!"
  end
end
