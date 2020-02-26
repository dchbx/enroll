# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# Validate latest VLP Document against V37 Contract for a given person
module Operations
  class ValidateVlpDocument
    send(:include, Dry::Monads[:result, :do])

    def call(person_id:)
      person = yield fetch_person(person_id)
      latest_vlp_doc = yield fetch_latest_vlp_document(person)
      yield validate_vlp_document(latest_vlp_doc)

      Success(person)
    end

    private

    def fetch_person(person_id)
      person = ::Person.where(_id: person_id).first
      person ? Success(person) : Failure('Person not found')
    end

    def fetch_latest_vlp_document(person)
      vlp_doc = person.consumer_role.vlp_documents.asc(:created_at).last
      vlp_doc ? Success(vlp_doc) : Failure('VLP Document not found')
    end

    def validate_vlp_document(vlp_doc)
      attributes = vlp_doc.attributes.merge({'expiration_date' => vlp_doc.expiration_date.to_s}).delete_if {|_k,v| v.blank?}
      result = ::Validators::VlpV37Contract.new.call(attributes)
      if result.failure?
        errors = result.errors.to_h
        message = if errors.values.flatten.include? 'Invalid VLP Document type'
                    "VLP document type is invalid: #{vlp_doc.subject}"
                  else
                    errors.keys.first.to_s.titlecase + ' ' + errors.values.flatten.first
                  end
        Failure(message)
      else
        Success(true)
      end
    end
  end
end
