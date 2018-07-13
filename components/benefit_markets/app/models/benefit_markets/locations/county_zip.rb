module BenefitMarkets
  module Locations
    # A County-Zip Code pair.  Used as the building block of the geographic
    # locations covered by both service areas and rating areas.
    class CountyZip
      include Mongoid::Document
      include Mongoid::Timestamps

      field :county_name, type: String
      field :zip, type: String
      field :state, type: String

      index({state: 1, county_name: 1, zip: 1})
    end
  end
end
