# frozen_string_literal: true

require 'i18n'
require 'dry-validation'

module BenefitSponsors
  class BaseDomainValidator < Dry::Validation::Contract
    config.messages.backend = :i18n
    config.messages.top_namespace = "dry_validation"
  end
end