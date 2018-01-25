class EventPublishers::FamilyEvent
  include EventPublishers::Base

  RESOURCE_NAME = EventPublishers::Base::CANONICAL_VOCABULARY_URI_V1 + "family"


  def household_event
  end

  def irs_group_event
  end

  def benefit_eligibility_event
    RESOURCE_NAME + "#benefit_eligibility_special_enrollment_period"
    RESOURCE_NAME + "#benefit_eligibility_assistance_determination"
  end

  def benefit_enrollment_event
    RESOURCE_NAME + "#benefit_enrollment_initial"
  end

  def benefit_enrollment_termination_event
    RESOURCE_NAME + "#benefit_enrollment_termination"
    RESOURCE_NAME + "#benefit_enrollment_auto_renewal"
    RESOURCE_NAME + "#benefit_enrollment_active_renewal"
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

end
