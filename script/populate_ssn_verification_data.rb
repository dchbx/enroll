# Set to NA for people with no SSN
Person.where("consumer_role" => {"$exists" => true, "$ne" => nil}, "encrypted_ssn" => {"$exists" => false}).update_all("$set" => {"consumer_role.ssn_validation" => "na"})

# People who did SSA or curam and passed
Person.where(
  "consumer_role" => {"$exists" => true, "$ne" => nil},
  "consumer_role.aasm_state" => "fully_verified",
  "consumer_role.lawful_presence_determination_vlp_authority" => {"$in" => ["ssa", "curam"]},
  "encrypted_ssn" => {"$ne" => nil}).update_all("$set" => {"consumer_role.ssn_validation" => "valid"})

Person.where(
  "consumer_role" => {"$exists" => true, "$ne" => nil},
  "consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding",
  "consumer_role.lawful_presence_determination_vlp_authority" => {"$in" => ["dhs"]},
  "encrypted_ssn" => {"$ne" => nil}).update_all("$set" => {"consumer_role.ssn_validation" => "outstanding"})
