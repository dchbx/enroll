# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SecureMessageAction
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params:, user: nil)
      validated_params = yield validate_params(params)
      resource = yield fetch_resource(validated_params)
      uploaded_doc = yield upload_document(resource, validated_params, user) if params[:file].present?
      uploaded_doc ||= params[:document] if params[:document].present?
      secure_message_result = yield upload_secure_message(resource, validated_params, uploaded_doc)
      result = yield send_generic_notice_alert(secure_message_result)
      Success(result)
    end

    private

    def validate_params(params)
      result = ::Validators::SecureMessageActionContract.new.call(params)

      result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
    end

    def fetch_resource(validate_params)
      if validate_params[:resource_name] == 'person'
        ::Operations::People::Find.new.call(person_id: validate_params[:resource_id])
      else
        profile_params = validate_params[:profile_id] ? { profile_id: validate_params[:profile_id] } : { organization_id: validate_params[:resource_id], profile_klass: validate_params[:resource_name] }
        profile = BenefitSponsors::Operations::Profiles::FindProfile.new.call(profile_params)
        return profile unless profile.success?

        resource =
          if validate_params[:resource_name] == 'broker_agency'
            profile.success&.primary_broker_role&.person
          elsif validate_params[:resource_name] == 'general_agency'
            profile.success&.general_agency_primary_staff&.person
          else
            profile.success
          end
        Success(resource)
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