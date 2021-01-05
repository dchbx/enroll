module BenefitSponsors
  class BenefitSponsorships::BenefitSponsorshipDirector
    include ::Acapi::Notifiers

    attr_reader :new_date

    def initialize(new_date = TimeKeeper.date_of_record)
      @new_date = new_date
      initialize_logger
    end

    def process(benefit_sponsorships, event)
      @logger.info "Now Processing event: #{event} on #{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%H:%M:%S')}"
      if event == :renew_sponsor_benefit
        benefit_sponsorships.no_timeout.each do |benefit_sponsorship|
          notify("acapi.info.events.benefit_sponsorship.execute_benefit_renewal", {
            :benefit_sponsorship_id => benefit_sponsorship.id.to_s, :new_date => new_date.strftime("%Y-%m-%d")
          })
        end
        return
      end

      business_policy_name = policy_name(event)
      benefit_sponsorships.no_timeout.each do |benefit_sponsorship|
        begin
          @logger.info "Processing legal_name: #{benefit_sponsorship.legal_name}"
          business_policy = business_policy_for(benefit_sponsorship, business_policy_name)
          sponsor_service_for(benefit_sponsorship).execute(benefit_sponsorship, event, business_policy)
        rescue Exception => e
          @logger.info "EXCEPTION: Event (#{event}) failed for Employer #{benefit_sponsorship.legal_name}(#{benefit_sponsorship.fein})"
          @logger.error e.message
          @logger.error e.backtrace.join("\n")
        end
      end
      @logger.info '-' * 50
    end

    def business_policy_for(benefit_sponsorship, business_policy_name)
      BenefitSponsors::BusinessPolicies::PolicyResolver.benefit_sponsorship_policy_for(benefit_sponsorship, business_policy_name)
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

    def initialize_logger
      @logger = Logger.new("#{Rails.root}/log/benefit_sponsorship_director.log") unless defined? @logger
    end
  end
end
