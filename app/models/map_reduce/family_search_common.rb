# frozen_string_literal: true

module MapReduce
  module FamilySearchCommon
    def map_function
      <<-JS_CODE
      function() {
         var fam = this;
         for (var i = 0; i < this["family_members"].length; i++) {
           var family_member = this["family_members"][i];
           var pers = people[family_member["person_id"].valueOf()];
           fam["family_members"][i]["person"] = pers;
           if (family_member["is_primary_applicant"]) {
             fam["primary_member"] = pers;
           }
         }
         delete(fam['versions']);
         delete(fam['version']);
         delete(fam['irs_groups']);
         delete(fam['households']);
         emit(fam._id, fam);
      }
      JS_CODE
    end

    def reduce_function
      <<-JS_CODE
      function(key, values) {
        return values;
      }
      JS_CODE
    end

    def people_hash_for(person_ids)
      person_data = {}
      Person.where({"_id" => {"$in" => person_ids}}).each do |pers|
        person_data[pers._id.to_s] = pers.as_json(:except => [
          :inbox, :versions, :version,
          :is_disabled, :is_tobacco_user,
          :phones, :emails, :addresses,
          :updated_at, :created_at,
          :updated_by_id
        ],
                                                  :include => {:consumer_role => {:except => [:vlp_documents, :updated_at, :created_at, :documents]}})
      end
      person_data
    end

    def reduced_collection
      Family.collection
    end
  end
end
