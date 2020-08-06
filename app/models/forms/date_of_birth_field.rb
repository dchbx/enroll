# frozen_string_literal: true

module Forms
  module DateOfBirthField
    def self.included(base)
      base.class_eval do
        attr_accessor :date_of_birth

        def dob
          Date.strptime(date_of_birth, "%Y-%m-%d")
        rescue StandardError
          nil
        end
      end
    end
  end
end
