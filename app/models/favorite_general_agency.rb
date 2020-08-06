# frozen_string_literal: true

class FavoriteGeneralAgency
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :broker_role
  field :general_agency_profile_id, type: BSON::ObjectId
  validates_presence_of :general_agency_profile_id
end
