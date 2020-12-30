# frozen_string_literal: true

module Validators
  module SecureMessages
    class MessageContract < ::Dry::Validation::Contract

      params do
        required(:subject).value(:string)
        required(:body).value(:string)
        optional(:from).maybe(:string)
      end

      rule(:subject) do
        key.failure('Please enter subject') if value.blank?
      end

      rule(:body) do
        key.failure('Please enter content') if value.blank?
      end
    end
  end
end
