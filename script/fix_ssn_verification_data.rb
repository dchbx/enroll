
Person.where(
    "consumer_role" => {"$exists" => true, "$ne" => nil},
    "consumer_role.lawful_presence_determination.vlp_authority" => {"$in" => ["curam"]}
).update_all("$set" => {"consumer_role.lawful_presence_determination.aasm_state" => "verification_successful"})
​
# Set to NA for people with no SSN
Person.where(
    "consumer_role" => {"$exists" => true, "$ne" => nil},
    "encrypted_ssn" => {"$exists" => false}).update_all("$set" => {"consumer_role.ssn_validation" => "na"})
​
# People who did SSA or curam and passed
Person.where(
    "consumer_role" => {"$exists" => true, "$ne" => nil},
    "consumer_role.lawful_presence_determination.aasm_state" => "verification_successful",
    "consumer_role.lawful_presence_determination.vlp_authority" => {"$in" => ["ssa", "curam"]},
    "encrypted_ssn" => {"$ne" => nil}).update_all("$set" => {"consumer_role.ssn_validation" => "valid"})
​
Person.where(
    "consumer_role" => {"$exists" => true, "$ne" => nil},
    "consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding",
    "consumer_role.lawful_presence_determination.vlp_authority" => {"$in" => ["ssa"]},
    "encrypted_ssn" => {"$ne" => nil}).update_all("$set" => {"consumer_role.ssn_validation" => "outstanding"})
​
Person.where(
    "consumer_role" => {"$exists" => true, "$ne" => nil},
    "consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding",
    "consumer_role.lawful_presence_determination.vlp_authority" => {"$in" => ["dhs"]},
    "encrypted_ssn" => {"$ne" => nil}).update_all("$set" => {"consumer_role.ssn_validation" => "outstanding"})