# frozen_string_literal: true

module Validators
  class SecureMessageActionContract < ::Dry::Validation::Contract

    params do
      required(:resource_id).value(:string)
      required(:resource_name).value(:string)
      required(:actions_id).filled(:string)
      required(:subject).value(:string)
      required(:body).value(:string)
      optional(:model_id).value(:string)
      optional(:model_klass).value(:string)
      optional(:file)
      optional(:document)
    end

    rule(:resource_id) do
      key.failure('Unable to find the resource') if value.blank?
    end

    rule(:resource_name) do
      key.failure('Unable to find the resource') if value.blank?
    end

    rule(:file) do
      key.failure('Invalid file format') if value.present? && !value.is_a?(ActionDispatch::Http::UploadedFile)
    end

    rule(:subject) do
      key.failure('Please enter subject') if value.blank?
    end

    rule(:body) do
      key.failure('Please enter content') if values[:file].blank? && value.blank?
    end
  end
end
