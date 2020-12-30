# frozen_string_literal: true

module Validators
  module Documents
    class UploadContract < ::Dry::Validation::Contract

      params do
        required(:subjects).value(:array)
        required(:id).value(:string)
        required(:document_type).value(:string)
        required(:source).value(:string)
      end

      rule(:subjects) do
        key.failure('Missing attributes for subjects') if value.blank?
      end

      rule(:id) do
        key.failure('Doc storage Identifier is blank') if value.blank?
      end

      rule(:document_type) do
        key.failure('Document type is missing') if value.blank?
      end

      rule(:source) do
        key.failure('Invalid source') if value != "enroll_system"
      end
    end
  end
end
