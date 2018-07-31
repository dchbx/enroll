module BenefitSponsors
  module Organizations
    module Factories
      class HbxProfile
        def self.call(office_locations)
          BenefitSponsors::Organizations::HbxProfile.new office_locations: office_locations
        end
      end
    end
  end
end
