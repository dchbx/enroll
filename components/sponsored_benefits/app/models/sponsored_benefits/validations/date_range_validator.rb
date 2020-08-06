# frozen_string_literal: true

module Validations
  class DateRangeValidator < ActiveModel::Validator
    DATA_TYPES = [Date, Time].freeze

    def validate(record)
      record.attributes.each_key do |key|
        if DATA_TYPES.include? record.attributes[key].class
          record.errors[key] << 'date cannot be more than 110 years ago' if record.attributes[key] < TimeKeeper.date_of_record - 110.years
        end
      end
    end
  end
end