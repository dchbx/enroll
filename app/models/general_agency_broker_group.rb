# frozen_string_literal: true

class GeneralAgencyBrokerGroup
  include Mongoid::Document
  embedded_in :broker_agency_profile

  field :name, type: String
  validates_presence_of :name
end
