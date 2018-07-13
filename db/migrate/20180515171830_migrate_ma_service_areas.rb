class MigrateMaServiceAreas < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      say_with_time("Build service areas linking them with county_zips") do

        old_carrier_profile_map = {}
        CarrierProfile.all.each do |cpo|
          cpo.issuer_hios_ids.each do |ihi|
            old_carrier_profile_map[ihi] = cpo.hbx_id
          end
        end

        new_carrier_profile_map = {}
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |ipo|
          i_profile = ipo.issuer_profile
          new_carrier_profile_map[ipo.hbx_id] = i_profile.id
        end

        service_area_collection = connection["carrier_service_areas"]
        service_area_state_aggregate = service_area_collection.find({}).aggregate([
          {"$match" => {
            "serves_entire_state" => true
          }},
          {"$group" => {
            "_id" => {
              "active_year" => "$active_year",
              "issuer_provided_code" => "$service_area_id",
              "issuer_hios_id" => "$issuer_hios_id"
            },
            "issuer_provided_title" => {"$last" => "$service_area_name"}
          }}
        ])

        service_area_state_aggregate.each do |rec|
          ::BenefitMarkets::Locations::ServiceArea.create!({
            active_year: rec["_id"]["active_year"],
            issuer_provided_code: rec["_id"]["issuer_provided_code"],
            covered_states: ["MA"],
            issuer_profile_id: new_carrier_profile_map[old_carrier_profile_map[rec["_id"]["issuer_hios_id"]]],
            issuer_provided_title: rec["issuer_provided_title"]
          })
        end

        service_area_non_state_aggregate = service_area_collection.find({}).aggregate([
          {"$match" => {
            "serves_entire_state" => false
          }},
          {"$group" => {
            "_id" => {
              "active_year" => "$active_year",
              "issuer_provided_code" => "$service_area_id",
              "issuer_hios_id" => "$issuer_hios_id"
            },
            "locations" => {
              "$push" => {
                   "county_name" => "$county_name",
                   "zip" => "$service_area_zipcode"
              }
            },
            "issuer_provided_title" => {"$last" => "$service_area_name"}
          }}
        ])

        service_area_non_state_aggregate.each do |rec|
          existing_state_wide_areas = ::BenefitMarkets::Locations::ServiceArea.where(
            active_year: rec["_id"]["active_year"].to_i,
            issuer_provided_code: rec["_id"]["issuer_provided_code"],
            issuer_profile_id: new_carrier_profile_map[old_carrier_profile_map[rec["_id"]["issuer_hios_id"]]]
          )
          next if existing_state_wide_areas.count > 0
          location_ids = rec['locations'].map do |loc_record|
            county_zip = ::BenefitMarkets::Locations::CountyZip.where({
             zip: loc_record['zip'],
             county_name: ::Regexp.compile(loc_record['county_name'], true)
            }).first
            county_zip._id
          end
          ::BenefitMarkets::Locations::ServiceArea.create!({
            active_year: rec["_id"]["active_year"],
            issuer_provided_code: rec["_id"]["issuer_provided_code"],
            issuer_profile_id: new_carrier_profile_map[old_carrier_profile_map[rec["_id"]["issuer_hios_id"]]],
            issuer_provided_title: rec["issuer_provided_title"],
            county_zip_ids: location_ids.uniq
          })
        end

      end
    else
      say("Skipping migration for non-MHC site")
    end
  end

  def self.down
    ::BenefitMarkets::Locations::ServiceArea.where.delete
  end
end
