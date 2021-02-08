# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SecureMessageAction
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params:, user: nil)
      validate_params = yield validate_params(params)
      resource = yield fetch_resource(validate_params)
      uploaded_doc = yield upload_document(resource, validate_params, user) if params[:file].present?
      uploaded_doc ||= params[:document] if params[:document].present?
      secure_message_result = yield upload_secure_message(resource, validate_params, uploaded_doc)
      result = yield send_generic_notice_alert(resource)
      Success(result)
    end

    private

    def validate_params(params)
      result = ::Validators::SecureMessageActionContract.new.call(params)

      result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
    end

    def fetch_resource(validate_params)
      if validate_params[:resource_name]&.classify&.constantize == Person
        ::Operations::People::Find.new.call(person_id: validate_params[:resource_id])
      else
        BenefitSponsors::Operations::Profiles::FindProfile.new.call(profile_id: validate_params[:resource_id])
      end
    end

    def upload_document(resource, params, user)
      ::Operations::Documents::Upload.new.call(resource: resource, file_params: params, user: user)
    end

    def upload_secure_message(resource, params, document)
      ::Operations::SecureMessages::Create.new.call(resource: resource, message_params: params, document: document)
    end

    def send_generic_notice_alert(resource)
      ::Operations::SendGenericNoticeAlert.new.call(resource: resource)
    end

  end
end