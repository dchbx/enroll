# frozen_string_literal: true

module Searches
  class FamilySearch
    include Mongoid::Document
    store_in collection: "family_search"
    embeds_one :primary_person, :class_name => "Searches::FamilySearchPerson"
    embeds_many :family_people, :class_name => "Searches::FamilySearchPerson"

    index({"primary_person.first_name" => 1, "primary_person.last_name" => 1})
  end
end
