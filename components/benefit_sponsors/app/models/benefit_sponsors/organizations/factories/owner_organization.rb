module BenefitSponsors
  module Organizations
    module Factories
      class OwnerOrganization
        def self.call(legal_name:, profile:)
          BenefitSponsors::Organizations::ExemptOrganization.new legal_name: legal_name, profiles: [ profile ]
        end
      end
    end
  end
end
