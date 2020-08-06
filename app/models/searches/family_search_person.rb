# frozen_string_literal: true

module Searches
  class FamilySearchPerson
    include Mongoid::Document
    embedded_in :family_search, :class_name => "Searches::FamilySearch"

    field :first_name, type: String
    field :middle_name, type: String
    field :last_name, type: String
    field :name_pfx, type: String
    field :name_sfx, type: String
    field :person_id, type: BSON::ObjectId
  end
end
