# frozen_string_literal: true

module MapReduce
  class FamilySearchForPerson
    include FamilySearchCommon

    def initialize(person)
      @person = person
    end

    def self.populate_for(person)
      self.new(person).execute
    end

    def family_ids_for(person)
      Family.collection.aggregate([
        {"$match" => {"family_members.person_id" => person.id}},
        {"$group" => {"_id" => "$_id"}}
      ]).map do |rec|
        rec['_id']
      end
    end

    def determine_person_ids(person)
      Family.collection.aggregate([
        {"$match" => {"family_members.person_id" => person.id}},
        {"$unwind" => "$family_members"},
        {"$group" => {"_id" => "$family_members.person_id"}}
      ]).map do |rec|
        rec['_id']
      end
    end

    def execute
      family_ids = family_ids_for(@person)
      @person_ids = determine_person_ids(@person)
      @map_reduce = Mongoid::Contextual::MapReduce.new(
        reduced_collection,
        Family.where({"_id" => {"$in" => family_ids}}),
        map_function,
        reduce_function
      )
      @map_reduce.scope({
                          people: people_hash_for(@person_ids)
                        })
      @map_reduce.out({merge: "families_search"})
      @map_reduce.counts
    end
  end
end
