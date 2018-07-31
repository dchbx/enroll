module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipService
    include ::Acapi::Notifiers

    INITIAL_EMPLOYER_TRANSMIT_EVENT     = "acapi.info.events.employer.benefit_coverage_initial_application_eligible"
    RENEWAL_EMPLOYER_TRANSMIT_EVENT     = "acapi.info.events.employer.benefit_coverage_renewal_application_eligible"
    RENEWAL_EMPLOYER_CARRIER_DROP_EVENT = "acapi.info.events.employer.benefit_coverage_renewal_carrier_dropped"
    INITIAL_APPLICATION_ELIGIBLE_EVENT_TAG     = "benefit_coverage_initial_application_eligible"
    RENEWAL_APPLICATION_ELIGIBLE_EVENT_TAG     = "benefit_coverage_renewal_application_eligible"
    RENEWAL_APPLICATION_CARRIER_DROP_EVENT_TAG = "benefit_coverage_renewal_carrier_dropped"

    attr_accessor :benefit_sponsorship, :new_date

    def initialize(benefit_sponsorship: nil, new_date: TimeKeeper.date_of_record)
      @benefit_sponsorship = benefit_sponsorship
      @new_date = new_date
    end

    def execute(benefit_sponsorship, event_name, business_policy = nil)
      self.benefit_sponsorship = benefit_sponsorship
      if business_policy.blank? || business_policy.is_satisfied?(benefit_sponsorship)
        process_event { eval(event_name.to_s) }
      else
        # log()
      end
    end

    def begin_open_enrollment
      benefit_application = benefit_sponsorship.application_may_begin_open_enrollment_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).begin_open_enrollment
      end
    end

    def end_open_enrollment
      benefit_application = benefit_sponsorship.application_may_end_open_enrollment_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).end_open_enrollment
      end

    end

    def begin_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_begin_benefit_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).begin_benefit
      end
    end

    def end_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_end_benefit_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).end_benefit
      end
    end

    def terminate_sponsor_benefit
      benefit_application = benefit_sponsorship.application_may_terminate_on(new_date)

      if benefit_application.present?
        application_service_for(benefit_application).terminate
      end
    end

    def renew_sponsor_benefit
      months_prior_to_effective = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months.abs
      renewal_application_begin = (new_date + months_prior_to_effective.months)

      benefit_application = benefit_sponsorship.application_may_renew_effective_on(renewal_application_begin)

      if benefit_application.present?
        application_service_for(benefit_application).renew_application
      end
    end

    def auto_submit_application
      effective_on = new_date.next_month.beginning_of_month
      benefit_application = benefit_sponsorship.application_may_auto_submit(effective_on)

      if benefit_application.present?
        application_service_for(benefit_application).force_submit_application
      end
    end

    def mark_initial_ineligible
      benefit_sponsorship.deny_initial_enrollment_eligibility! if benefit_sponsorship.may_deny_initial_enrollment_eligibility?
    end

    def auto_cancel_ineligible
      benefit_sponsorship.cancel! if benefit_sponsorship.may_cancel?      
    end

    def transmit_initial_eligible_event
      notify(INITIAL_EMPLOYER_TRANSMIT_EVENT, {employer_id: benefit_sponsorship.profile.hbx_id, event_name: INITIAL_APPLICATION_ELIGIBLE_EVENT_TAG})
    end

    def transmit_renewal_eligible_event
      notify(RENEWAL_EMPLOYER_TRANSMIT_EVENT, {employer_id: benefit_sponsorship.profile.hbx_id, event_name: RENEWAL_APPLICATION_ELIGIBLE_EVENT_TAG})
    end

    def transmit_renewal_carrier_drop_event
      notify(RENEWAL_EMPLOYER_CARRIER_DROP_EVENT, {employer_id: benefit_sponsorship.profile.hbx_id, event_name: RENEWAL_APPLICATION_CARRIER_DROP_EVENT_TAG})
    end

    def self.set_binder_paid(benefit_sponsorship_ids)
      benefit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"_id".in => benefit_sponsorship_ids)
      benefit_sponsorships.each {|benefit_sponsorship| benefit_sponsorship.credit_binder! if benefit_sponsorship.may_credit_binder?}
    end

    private

    def enrollment_policy
      return @enrollment_policy if defined?(@enrollment_policy)
      @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
    end

    def business_policy_for(benefit_application, event_name)
      enrollment_policy.business_policies_for(benefit_application, event_name)
    end

    def application_service_for(benefit_application)
      BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
    end

    def process_event(&block)
      begin
        block.call
      rescue Exception => e
      end
    end
  end
end
