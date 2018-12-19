class MigrateDcServiceAreas < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      say_with_time("Build service areas for DC") do
        [2014, 2015,2016,2017,2018,2019].each do |year|
          ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
            # Todo check on issuer_provided_code, for now set with issuer profile hbx_id
            issuer_profile = issuer_organization.issuer_profile
            if self.carrier_exists_in_the_year(issuer_profile, year)
              ::BenefitMarkets::Locations::ServiceArea.create!({
                                                                   active_year: year,
                                                                   issuer_provided_code: "DCS001",
                                                                   covered_states: ["DC"],
                                                                   issuer_profile_id: issuer_profile.id,
                                                                   issuer_provided_title: issuer_profile.legal_name
                                                               })
            end
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
      ::BenefitMarkets::Locations::ServiceArea.all.delete_all
    else
      say("Skipping migration for non-DC site")
    end
  end
end