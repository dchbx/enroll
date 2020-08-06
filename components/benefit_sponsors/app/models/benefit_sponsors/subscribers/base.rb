# frozen_string_literal: true

module BenefitSponsors
  module Subscribers
    module Base
      def extract_response_params(properties)
        headers = properties.headers || {}
        stringed_headers = headers.stringify_keys
        correlation_id = properties.correlation_id
        workflow_id = stringed_headers["workflow_id"]

        response_params = {}
        response_params[:correlation_id] = correlation_id if correlation_id.present?
        response_params[:workflow_id] = workflow_id if workflow_id.present?

        response_params
      end

      def extract_workflow_id(properties)
        headers = properties.headers || {}
        stringed_headers = headers.stringify_keys
        stringed_headers["workflow_id"] || SecureRandom.uuid.gsub("-","")
      end
    end
  end
end