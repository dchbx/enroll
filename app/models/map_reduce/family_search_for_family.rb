# frozen_string_literal: true

module MapReduce
  class FamilySearchForFamily
    include FamilySearchCommon

    def self.populate_for(family)
      self.new(family).execute
    end

    def initialize(family)
      @family = family
      @person_ids = family.family_members.map(&:person_id)
      @map_reduce = Mongoid::Contextual::MapReduce.new(
        reduced_collection,
        Family.where({"_id" => family._id}),
        map_function,
        reduce_function
      )
      @map_reduce.out({merge: "families_search"})
    end

    def execute
      @map_reduce.scope({
                          people: people_hash_for(@person_ids)
                        })
      @map_reduce.counts
    end
  end
end
