# frozen_string_literal: true

# Organization type with relaxed data entry/validation policies used for government agencies,
# embassies and other types where FEIN is not assigned/available
module BenefitSponsors
  module Organizations
    class ExemptOrganization < BenefitSponsors::Organizations::Organization
      scope :by_profile_id, ->(profile_id){ where("profiles._id" => BSON::ObjectId.from_string(profile_id)) }
    end
  end
end
