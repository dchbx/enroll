# frozen_string_literal: true

module FinancialAssistance
  module Forms
    module DateOfBirthField
      def self.included(base)
        base.class_eval do
          attr_accessor :dob

          def dob
            Date.strptime(dob, "%Y-%m-%d")
          rescue StandardError # rubocop:disable Lint/EmptyRescueClause
            nil
          end

          def dob=(val)
            @dob = begin
              Date.strptime(val, "%Y-%m-%d")
                   rescue StandardError # rubocop:disable Lint/EmptyRescueClause
                     nil
            end
          end
        end
      end
    end
  end
end
