# frozen_string_literal: true

module ViewFunctions
  class Family
    def self.run_after_save_search_update(family_id)
      ::Family.collection.database.command({"eval" => "db.families.find(ObjectId(\"#{family_id}\")).forEach(function(doc) { db.loadServerScripts(); familySavedSearchUpdate(doc); })", "nolock" => true})
    end

    def self.install_queries
      ::Family.collection.database["system.js"].where({"_id" => "familySavedSearchUpdate"}).upsert({:id => "familySavedSearchUpdate", :value => BSON::Code.new(after_save_search_update_function)})
    end

    def self.after_save_search_update_function
      # Name: familySavedSearchUpdate
      <<~MONGOJS
        function(familyDoc) {
            var peopleIds = [];
            var primaryId = null;
            var primaryPerson = null;
            var familyPeople = [];
            familyDoc.family_members.forEach(function(fm) {
               if (fm.is_active) {
                 if (fm.is_primary_applicant) {
                     primaryId = fm.person_id;
                 }
                 peopleIds.push(fm.person_id);
               }
            });
            db.people.find({_id: {$in: peopleIds}}).forEach(function(per) {
                if (per._id.equals(primaryId)) {
                  primaryPerson = {
                    person_id: per._id,
                    first_name: per.first_name,
                    last_name: per.last_name
                  };
                  if (!((per.middle_name == null) || (per.middle_name == undefined))) {
                      primaryPerson['middle_name'] = per.middle_name
                  }
                  if (!((per.name_pfx == null) || (per.name_pfx == undefined))) {
                      primaryPerson['name_pfx'] = per.name_pfx
                  }
                  if (!((per.name_sfx == null) || (per.name_sfx == undefined))) {
                      primaryPerson['name_sfx'] = per.name_sfx
                  }
                  familyPeople.push(primaryPerson);
                } else {
                    var personRecord = {
                    person_id: per._id,
                    first_name: per.first_name,
                    last_name: per.last_name
                    };
                  if (!((per.middle_name == null) || (per.middle_name == undefined))) {
                      personRecord['middle_name'] = per.middle_name
                  }
                  if (!((per.name_pfx == null) || (per.name_pfx == undefined))) {
                      personRecord['name_pfx'] = per.name_pfx
                  }
                  if (!((per.name_sfx == null) || (per.name_sfx == undefined))) {
                      personRecord['name_sfx'] = per.name_sfx
                  }
                    familyPeople.push(personRecord);
                }
            });
            db.family_search.update(
            {_id: familyDoc._id},
            {
              _id: familyDoc._id,
              primary_person: primaryPerson,
              family_people: familyPeople
            },
            {upsert: true});
        }
      MONGOJS
    end
  end
end
