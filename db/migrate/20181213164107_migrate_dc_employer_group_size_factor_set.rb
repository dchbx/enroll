class MigrateDcEmployerGroupSizeFactorSet < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      [2014, 2015,2016,2017,2018,2019].each do |year|
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
          issuer_profile = issuer_organization.issuer_profile
          if self.carrier_exists_in_the_year(issuer_profile, year)
            ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.create!(
                active_year: year,
                default_factor_value: 1.0,
                max_integer_factor_key: 1,
                issuer_profile_id: issuer_profile.id,
                actuarial_factor_entries: []
            )
          end
        end
      end
    else
      say("Skipping migration for non-DC site")
    end
  end

  def self.carrier_exists_in_the_year(issuer_profile, year)
    carrier_profile =  Organization.where(hbx_id: issuer_profile.hbx_id).first.carrier_profile
    Plan.where(carrier_profile_id:carrier_profile.id, active_year: year).present?
  end

  def self.down
    if Settings.site.key.to_s == "dc"
      ::BenefitMarkets::Products::ActuarialFactors::ActuarialFactor.delete_all
    else
      say("Skipping migration for non-DC site")
    end
  end
end
