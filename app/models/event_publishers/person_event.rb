class EventPublishers::PersonEvent
  include EventPublishers::Base

  RESOURCE_NAME = EventPublishers::Base::CANONICAL_VOCABULARY_URI_V1 + "individual"


  def identity_event
    RESOURCE_NAME + "#fein_corrected"
    RESOURCE_NAME + "#name_changed"

  end

  def location_event
    RESOURCE_NAME + "#address_changed"
  end


end
