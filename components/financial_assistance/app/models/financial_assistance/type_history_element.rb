# frozen_string_literal: true

module FinancialAssistance
  class TypeHistoryElement
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :verification_type

    field :action, type: String   #tracked action [verify, reject, call_hub, upload_document, delete_document, hub_request, hub_response]
    field :modifier, type: String #current user or external source
    field :update_reason, type: String #reason selected by admin from menu
    field :event_response_record_id, type: String #reference to event response model with raw payload
    field :event_request_record_id, type: String #reference to event request model with raw request
  end
end