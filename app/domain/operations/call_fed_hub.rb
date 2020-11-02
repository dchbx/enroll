# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  # Call Fed Hub for Verification for Consumer Document Verification
  class CallFedHub
    send(:include, Dry::Monads[:result, :do])

    def call(person_id:, verification_type:)
      person = if verification_type == 'Immigration status'
                 yield verify_vlp_document(person_id)
               else
                 yield fetch_person(person_id)
               end

      yield call_fed_hub(person, verification_type)
      assign_message(verification_type)
    end

    private

    def verify_vlp_document(person_id)
      result = ::Operations::ValidateVlpDocument.new.call(person_id: person_id)
      if result.success?
        result
      else
        Failure([:danger, result.failure])
      end
    end

    def fetch_person(person_id)
      person = ::Person.where(_id: person_id).first
      person ? Success(person) : Failure([:danger, 'Person not found'])
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
