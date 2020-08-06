# frozen_string_literal: true

module BenefitSponsors
  module CensusMembers
    class CensusSurvivor < CensusMembers::CensusMember

      embeds_many :census_dependents, as: :census_dependent,
                                      cascade_callbacks: true,
                                      validate: true
    end
  end
end
