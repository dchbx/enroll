class GeneralAgencyStaffRole
  include Mongoid::Document

  embedded_in :person
  field :npn, type: String
  field :general_agency_profile_id, type: BSON::ObjectId
  field :aasm_state, type: String, default: "applicant"

  validates :npn, 
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },    
    uniqueness: true,
    allow_blank: false

end
