# frozen_string_literal: true

module Validators
  module Documents
    class DocumentContract < ::Dry::Validation::Contract

      params do
        required(:title).value(:string)
        required(:creator).value(:string)
        required(:subject).value(:string)
        required(:doc_identifier).value(:string)
        required(:format).value(:string)
      end

      rule(:title) do
        key.failure('Missing title for document.') if value.blank?
      end

      rule(:creator) do
        key.failure('Missing creator for document.') if value.blank?
      end

      rule(:subject) do
        key.failure('Missing subject for document.') if value.blank?
      end

      rule(:doc_identifier) do
        key.failure('Response missing doc identifier.') if value.blank?
      end

      rule(:format) do
        key.failure('Invalid file format.') unless %w[application/pdf image/png image/jpeg].include? value
      end
    end
  end
end
