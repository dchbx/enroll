module SponsoredApplications
  class SponsorBenefits::SponsorBenefit < SponsorBenefits::CompositeTask

    def initialize
      super("Process an organization and it's members initial benefit coverage")

# binding.pry
      add_subtask(SponsorBenefits::FindOrCreateSponsorOrganization.new)
      add_subtask(SponsorBenefits::HireBroker.new)
      add_subtask(SponsorBenefits::DesignBenefit.new)
      add_subtask(SponsorBenefits::ConductOpenEnrollment.new)
      add_subtask(SponsorBenefits::CreditBinderPremium.new)
      add_subtask(SponsorBenefits::EffectuateCoverage.new)
    end


  end
end
