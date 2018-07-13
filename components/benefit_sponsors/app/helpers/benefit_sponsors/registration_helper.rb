module BenefitSponsors
  module RegistrationHelper

    def is_broker_profile?(profile_type)
      profile_type == "broker_agency"
    end

    def is_sponsor_profile?(profile_type)
      profile_type == "benefit_sponsor"
    end
  end
end
