# frozen_string_literal: true

require 'i18n'
require 'dry-schema'
require 'date'
require 'mail'

module BenefitSponsors
  module ValidationTypes
    include Dry::Types()
  end

  BsonObjectIdString = ValidationTypes.Constructor(BSON::ObjectId) do |value|

    BSON::ObjectId.from_string(value)
  rescue BSON::ObjectId::Invalid
    nil

  end

  class BaseParamValidator < Dry::Schema::Params
    define do
      config.messages.backend = :i18n
      config.messages.load_paths += Dir[
        Rails.root.join('config', 'locales', 'dry_validation.*.yml')
      ]
    end
  end

  module CommonPredicates
    def us_date?(value)
      (begin
         Date.strptime(value, "%m/%d/%Y")
       rescue StandardError
         nil
       end).present?
    end

    def email?(value)
      parsed = Mail::Address.new(value)
      true
    rescue Mail::Field::ParseError => e
      false
    end
  end

  Dry::Logic::Predicates.extend(CommonPredicates)
end