# frozen_string_literal: true
class EnrollmentEligibilityReason

  attr_reader :reason_provider, :date_of_reason

  delegate :type, :reason, to: :reason_provider

  def initialize(provider)
    self.provider = provider
  end

  def provider=(new_provider_object, _date_of_reason = TimeKeeper.date_of_record)
    @provider = ReasonProvider.new(new_provider_object)
  end


  class ReasonProvider
    include Config::AcaModelConcern

    def initialize(provider)
      case provider.class
      when SpecialEnrollmentPeriod
        SpecialEnrollmentPeriodReasonProvider.new(provider)
      when ->(klass) { benefit_sponsors.include?(klass) }
        EmployerProfileReasonProvider.new(provider)
      when BenefitSponsorship
        BenefitSponsorshipReasonProvider.new(provider)
      else
        raise ArgumentError.new, "invalid provider class: #{provider.class}"
      end
    end

    def benefit_sponsors
      site_key = EnrollRegistry[:enroll_app].setting(:site_key).item.capitalize
      sponsor_classes = ["BenefitSponsors::Organizations::AcaShop#{site_key}EmployerProfile".constantize]
      sponsor_classes << "BenefitSponsors::Organizations::FehbEmployerProfile".constantize if fehb_market_is_enabled?
      sponsor_classes
    end
  end

  class EmployerProfileReasonProvider < ReasonProvider
    attr_reader :employer_profile

    def initialize((employer_profile)) = @employer_profile = employer_profile

    def type() = "open_enrollment_period"

    def reason() = "open_enrollment"
  end

  class BenefitSponsorshipReasonProvider < ReasonProvider
    attr_reader :benefit_sponsorship

    def initialize((benefit_sponsorship)) = @benefit_sponsorship = benefit_sponsorship

    def type() = "open_enrollment_period"

    def reason() = "open_enrollment"
  end

  class SpecialEnrollmentPeriodReasonProvider < ReasonProvider
    attr_reader :special_enrollment_period

    def initialize((special_enrollment_period)) = @special_enrollment_period = special_enrollment_period

    def type() = "special_enrollment_period"

    def reason
      special_enrollment_period.qualifying_life_event_kind.reason
    end
  end
end
