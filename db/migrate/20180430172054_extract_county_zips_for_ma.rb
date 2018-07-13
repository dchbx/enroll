class ExtractCountyZipsForMa < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      carrier_service_areas = connection["carrier_service_areas"]
      rating_areas = connection["rating_areas"]
      if carrier_service_areas
        say_with_time("Extract counties and zips using service areas as our source") do
          carrier_service_areas.find({}).aggregate([
            {"$match" => {serves_entire_state: false}},
            {"$group" => {_id: {zip_code: "$service_area_zipcode", county_name: "$county_name"}}},
            {"$project" => {zip: "$_id.zip_code", county_name: "$_id.county_name", state: "MA", _id: 0}},
            {"$out" => "benefit_markets_locations_county_zips"}
          ]).each 
        end
      end
      if rating_areas
        say_with_time("Extract additional counties and zips using rating areas as our source") do
          rating_areas.find({}).aggregate([
            {"$group" => {_id: {zip_code: "$zip_code", county_name: "$county_name"}}},
            {"$project" => {zip: "$_id.zip_code", county_name: "$_id.county_name", state: "MA", _id: 0}},
          ]).each do |ra_record|
            found_existing_record = ::BenefitMarkets::Locations::CountyZip.where({
              county_name: ra_record['county_name'],
              zip: ra_record['zip']
            }).any?
            unless found_existing_record
              ::BenefitMarkets::Locations::CountyZip.create!({
                county_name: ra_record['county_name'],
                zip: ra_record['zip'],
                state: "MA"
              }) 
            end
          end
        end
      end
    end
  end

  def self.down
    ::BenefitMarkets::Locations::CountyZip.all.delete
  end
end
