# Individual Market Primary Member
module BenefitSponsors
  class Members::FamilyMember < Members::Member


    # Person is applying for coverage
    field :is_coverage_applicant, type: Boolean, default: true

    # Person who authorizes auto-renewal eligibility check
    field :is_consent_applicant, type: Boolean, default: false

    after_initialize :set_self_relationship


    private

    def set_self_relationship
      kinship_to_primary_member = :self
    end
  end

end
