class EventPublishers::EmployerProfileEvent
  include EventPublishers::Base

  RESOURCE_NAME = EventPublishers::BaseCANONICAL_VOCABULARY_URI_V1 + "employer"

  def initialize(options = {})
    unless options.has_key?(:employer_profile_transcript)
      raise ArgumentError, ""
    end

    @employer_profile_transcript = options[:employer_profile_transcript]
  end

  def broker_event
    RESOURCE_NAME + "#broker_added"
    RESOURCE_NAME + "#broker_terminated"
  end

  # General Agent
  def ga_event
    RESOURCE_NAME + "#ga_added"
    RESOURCE_NAME + "#ga_terminated"
  end

  def identity_event
    RESOURCE_NAME + "#fein_corrected"
    RESOURCE_NAME + "#name_changed"

  end

  def location_event
    RESOURCE_NAME + "#address_changed"
  end

  def point_of_contact_event
    RESOURCE_NAME + "#contact_changed"
  end

  def benefit_coverage_initial_event
    RESOURCE_NAME + "#benefit_coverage_initial_application_approved"
    RESOURCE_NAME + "#benefit_coverage_initial_open_enrollment_ended"
    RESOURCE_NAME + "#benefit_coverage_initial_binder_paid"
    RESOURCE_NAME + "#benefit_coverage_initial_application_eligible"
  end

  def benefit_coverage_renewal_event
    RESOURCE_NAME + "#benefit_coverage_renewal_open_enrollment_ended"
    RESOURCE_NAME + "#benefit_coverage_renewal_terminated_ineligible"
    RESOURCE_NAME + "#benefit_coverage_renewal_terminated_eligible"
    RESOURCE_NAME + "#benefit_coverage_renewal_carrier_dropped"
  end

  def benefit_coverage_period_event
    RESOURCE_NAME + "#benefit_coverage_period_terminated_voluntary"
    RESOURCE_NAME + "#benefit_coverage_period_terminated_relocated"
    RESOURCE_NAME + "#benefit_coverage_period_terminated_nonpayment"
    RESOURCE_NAME + "#benefit_coverage_period_terminated_reinstated"
    RESOURCE_NAME + "#benefit_coverage_period_terminated_expired"
  end
end
