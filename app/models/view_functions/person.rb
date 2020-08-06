# frozen_string_literal: true

module ViewFunctions
  class Person
    def self.run_after_save_search_update(person_id)
      ::Person.collection.database.command({"eval" => "db.people.find(ObjectId(\"#{person_id}\")).forEach(function(doc) { db.loadServerScripts(); personSaveUpdateFamilySearch(doc); })", "nolock" => true})
    end

    def self.install_queries
      ::Person.collection.database["system.js"].where({"_id" => "personSaveUpdateFamilySearch"}).upsert({:id => "personSaveUpdateFamilySearch", :value => BSON::Code.new(person_save_family_search_update)})
    end

    def self.person_save_family_search_update
      # name: personSaveFamilySearchUpdate
      <<~MONGOJS
        function(personDoc) {
            db.families.find(
             { family_members: { $elemMatch: {
                 person_id: personDoc._id
             }}}).forEach(function(doc) {
                familySavedSearchUpdate(doc);
            });
        }
      MONGOJS
    end
  end
end
