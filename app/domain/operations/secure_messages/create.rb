# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module SecureMessages
    class Create
      include Config::SiteConcern
      send(:include, Dry::Monads[:result, :do])

      #resource can be a profile or person who has inbox as embedded document

      def call(resource:, message_params:, document:)
        recipient = yield fetch_recipient(resource)
        payload = yield construct_message_payload(recipient, message_params, document)
        validated_payload = yield validate_message_payload(payload)
        message_entity = yield create_message_entity(validated_payload)
        resource = yield create(recipient, message_entity.to_h)

        Success(resource)
      end

      private

      def fetch_recipient(resource)
        recipient = resource.is_a?(BenefitSponsors::Organizations::BrokerAgencyProfile) ? resource&.primary_broker_role&.person : resource
        return Failure({:message => ['Please find valid resource to send the message']}) if recipient.blank?

        Success(recipient)
      end

      def construct_message_payload(resource, message_params, document)
        # rubocop:disable Layout/LineLength - when breaking into different lines anchor tag is failing to construct href. Tried several approaches.
        body = if document.present?
                 message_params[:body] + "<br>You can download the notice by clicking this link " \
                   "<a href=" \
                   "#{Rails.application.routes.url_helpers.cartafact_document_download_path(message_params[:model_klass] || resource.class.to_s,
                                                                                            message_params[:model_id] || resource.id.to_s, 'documents', document.id)}?content_type=#{document.format}&filename=#{document.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" \
                   " target='_blank'>" + document.title.gsub(/[^0-9a-z.]/i,'') + "</a>"
               else
                 message_params[:body]
               end
        # rubocop:enable Layout/LineLength

        Success({ :subject => message_params[:subject],
                  :body => body,
                  :from => site_short_name })
      end

      def validate_message_payload(params)
        result = ::Validators::SecureMessages::MessageContract.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def create_message_entity(params)
        message = ::Entities::SecureMessages::Message.new(params)
        Success(message)
      end

      def create(resource, message_entity)
        resource.inbox.messages << Message.new(message_entity)
        resource.save!
        Success(resource)
      end

    end
  end
end
