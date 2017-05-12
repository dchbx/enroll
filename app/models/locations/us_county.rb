class Locations::UsCounty
  include Mongoid::Document

  belongs_to :geographic_rating_area

  field :state_postal_code, type: String
  field :state_fips_code, type: String
  field :county_fips_code, type: String
  field :county_name, type: String
  field :fips_class_code, type: String

  index({county_fips_code:  1}, {unique: true})
  index({state_postal_code: 1})

end
