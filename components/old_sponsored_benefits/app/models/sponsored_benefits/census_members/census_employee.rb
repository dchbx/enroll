module SponsoredBenefits::CensusMembers
  class CensusEmployee < CensusMember

    has_many :census_survivors, class_name: "SponsoredBenefits::CensusMembers::CensusSurvivor"
    embeds_many :census_dependents, as: :census_dependent, class_name: "SponsoredBenefits::CensusMembers::CensusDependent"
    
  end
end
