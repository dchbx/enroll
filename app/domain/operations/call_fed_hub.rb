# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# Call Fed Hub for Verification for Consumer Document Verification
module Operations
  class CallFedHub
    send(:include, Dry::Monads[:result, :do])

    def call(person_id:, verification_type:)
      person = yield fetch_person(person_id)
      if verification_type == 'Immigration status'
        latest_vlp_doc = yield fetch_latest_vlp_document(person)
        yield validate_vlp_document(latest_vlp_doc)
      end
      yield call_fed_hub(person, verification_type)
      assign_message(verification_type)
    end

    private

    def fetch_person(person_id)
      person = ::Person.find(person_id)
      person ? Success(person) : Failure([:danger, 'Person not found'])
    end

    def fetch_latest_vlp_document(person)
      vlp_doc = person.consumer_role.vlp_documents.asc(:created_at).last
      vlp_doc ? Success(vlp_doc) : Failure([:danger, 'VLP Document not found'])
    end

    def validate_vlp_document(vlp_doc)
      attributes = vlp_doc.attributes.merge({"expiration_date" => vlp_doc.expiration_date.to_s}).delete_if {|_k,v| v.blank?}
      result = ::Validators::VlpV37Contract.new.call(attributes)
      if result.failure?
        errors = result.errors.to_h
        message = if errors.values.flatten.include? "Invalid VLP Document type"
                    "VLP document type is invalid: #{vlp_doc.subject}"
                  else
                    errors.keys.first.to_s.titlecase + ' ' + errors.values.flatten.first
                  end
        Failure([:danger, message])
      else
        Success(true)
      end
    end

    def call_fed_hub(person, verification_type)
      if verification_type == 'DC Residency'
        person.consumer_role.invoke_residency_verification!
      else
        person.consumer_role.redetermine_verification!(OpenStruct.new({:determined_at => Time.zone.now, :authority => 'hbx'}))
      end

      Success(true)
    end

    def assign_message(verification_type)
      hub = verification_type == 'DC Residency' ? 'Local Residency' : 'FedHub'
      message = "Request was sent to #{hub}."
      Success([:success, message])
    end
  end
end
