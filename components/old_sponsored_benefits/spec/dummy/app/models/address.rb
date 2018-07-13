 class Address
 include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :office_location

  # The type of address
  field :kind, type: String

  field :address_1, type: String
  field :address_2, type: String, default: ""
  field :address_3, type: String, default: ""

  # The name of the city where this address is located
  field :city, type: String

  # The name of the county where this address is located
  field :county, type: String, default: ''

  # The name of the U.S. state where this address is located
  field :state, type: String

  # @todo Add support for FIPS codes
  field :location_state_code, type: String

  # @deprecated Use {#to_s} or {#to_html} instead
  field :full_text, type: String

  # The postal zip code where this address is located
  field :zip, type: String

  # The name of the country where this address is located
  field :country_name, type: String, default: ""

end