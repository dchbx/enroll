# frozen_string_literal: true

class Contact
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :broker_agency
  embedded_in :employer

  field :company_name, type: String, default: ""
  field :first_name, type: String
  field :middle_name, type: String, default: ""
  field :last_name, type: String
  field :name_sfx, type: String, default: ""
  field :name_full, type: String
  field :alternate_name, type: String, default: ""

  embeds_many :addresses
  embeds_many :phones
  embeds_many :emails

end
