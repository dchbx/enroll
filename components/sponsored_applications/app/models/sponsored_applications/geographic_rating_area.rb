module SponsoredApplications
  class GeographicRatingArea
    include Mongoid::Document


    belongs_to :marketplace
    has_one :us_county
    has_one :zip_code

  end
end
