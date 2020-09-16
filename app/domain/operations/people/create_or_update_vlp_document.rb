# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdateVlpDocument
      include Dry::Monads[:result, :do]

      def call(params:)
        values = yield validate(params[:applicant_params])
        vlp_document_params = yield create_entity(values)
        vlp_document = yield create_or_update_vlp_document(vlp_document_params, params[:person])

        Success(vlp_document)
      end

      private

      def sanitize_params(params)
        params[:subject] = params.delete :vlp_subject
        params
      end

      def validate(params)
        result = Validators::Families::VlpDocumentContract.new.call(sanitize_params(params))

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_entity(values)
        result = Entities::VlpDocument.new(values.to_h)

        Success(result)
      end

      def create_or_update_vlp_document(vlp_document_params, person)
        vlp_document = person.consumer_role.find_document(vlp_document_params[:subject])
        vlp_document.assign_attributes(vlp_document_params.to_h)

        person.consumer_role.active_vlp_document_id = vlp_document.id
        Person.skip_callback(:update, :after, :person_create_or_update_handler)
        person.save!
        Person.set_callback(:update, :after, :person_create_or_update_handler)

        Success(vlp_document)

      rescue StandardError => e
        Failure(person.errors.messages)
      end
    end
  end
end

