class ExtractRatingAreasForMa < Mongoid::Migration
  def self.up
    rating_areas = connection["rating_areas"]
    if rating_areas
      say_with_time("Build rating areas linking them with county_zips") do
        rating_areas.find({}).aggregate([
          {"$group" => {
            "_id" => "$rating_area",
            "locations" => {
              "$push" => {
                "county_name" =>"$county_name",
                "zip" => "$zip_code"
              }
          }}}
        ]).each do |ra_record|
          rating_area_name = ra_record['_id']
          location_ids = ra_record['locations'].map do |loc_record|
            county_zip = ::BenefitMarkets::Locations::CountyZip.where({
             zip: loc_record['zip'],
             county_name: loc_record['county_name']
            }).first
            county_zip._id
          end
          ::BenefitMarkets::Locations::RatingArea.create!({
             active_year: 2017,
             exchange_provided_code: rating_area_name,
             county_zip_ids: location_ids
          })
          ::BenefitMarkets::Locations::RatingArea.create!({
             active_year: 2018,
             exchange_provided_code: rating_area_name,
             county_zip_ids: location_ids
          })
        end
      end
    end
  end

  def self.down
    ::BenefitMarkets::Locations::RatingArea.where.delete
  end
end
