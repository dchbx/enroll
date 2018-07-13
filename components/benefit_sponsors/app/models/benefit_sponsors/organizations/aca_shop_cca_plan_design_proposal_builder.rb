module BenefitSponsors
  module Organizations
    class AcaShopCcaPlanDesignProposalBuilder < BenefitSponsors::Organizations::PlanDesignProposalBuilder



      def initialize(plan_design_organization, effective_date, options={})
        super()
        @plan_design_proposal = AcaShopCcaPlanDesignProposal.new
        @benefit_market = :aca_shop_cca
        @sic_code = options[:sic_code] 

      end

      def add_plan_design_profile(new_plan_design_profile, sic_code)
        raise "profile must include primary office location" unless new_plan_design_profile.primary_office_location.present?

        @sic_code = sic_code
        @plan_design_profile = BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(sic_code: @sic_code, eligible_for_benefit_sponsorship: true)
        @plan_design_proposal.plan_design_profile = @plan_design_profile

        @plan_design_profile
      end

      # def add_benefit_application(new_benefit_application)
      #   fail NotImplementedError, 'abstract'
      # end

      def add_employer_attestation(new_employer_attestation)
      end


      def plan_design_proposal
        raise ArgumentError, "must provide sic_code" unless @sic_code.present?
        super
      end

    end
  end
end
