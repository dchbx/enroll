# frozen_string_literal: true

module Validators
  module Families
    class EligibilityDeterminationContract < Dry::Validation::Contract
# this contract is an application attributes along with the below attributes expected by FAA

# family_id
#assistance_year
#array of applicants ######validators::Families::ApplicantContract
#array of eligibility_determinations

#----bi directional main app - faa---
#years_to_renew -  #renewal_consent_through_year family.rb

#benchmark_product_id
#is_ridp_verified

#---#review-----are we using this in enroll?
#is_requesting_voter_registration_application_in_mail


#add rule to verify existing family id
    end
  end
end
