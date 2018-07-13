class Phone
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :office_location

  field :kind, type: String
  field :country_code, type: String, default: ""
  field :area_code, type: String, default: ""
  field :number, type: String, default: ""
  field :extension, type: String, default: ""
  field :primary, type: Boolean
  field :full_phone_number, type: String, default: ""
end