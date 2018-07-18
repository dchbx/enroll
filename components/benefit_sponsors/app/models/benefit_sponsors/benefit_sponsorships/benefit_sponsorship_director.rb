module BenefitSponsors
  class BenefitSponsorships::BenefitSponsorshipDirector

    attr_reader :new_date

    def initialize(new_date = TimeKeeper.date_of_record)
      @new_date = new_date
    end

    def process(benefit_sponsorship, event)
      begin
        business_policy_name = policy_name(event)
        business_policy = business_policy_for(benefit_sponsorship, business_policy_name)
        sponsor_service_for(benefit_sponsorship).execute(benefit_sponsorship, event, business_policy)
      rescue Exception => e 
      end
    end

    def business_policy_for(benefit_sponsorship, business_policy_name)
      sponsor_policy.business_policies_for(benefit_sponsorship, business_policy_name)
    end

    def sponsor_service_for(benefit_sponsorship)
      if benefit_sponsorship.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
        sponsorship_service
      end
    end

    def policy_name(event_name)
      event_name
    end

    private

    def sponsorship_service
      return @sponsorship_service if defined? @sponsorship_service
      @sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(new_date: new_date)
    end

    def sponsor_policy
      return @sponsor_policy if defined?(@sponsor_policy)
      @sponsor_policy = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipPolicy.new
    end
  end
end