# frozen_string_literal: true

module FinancialAssistance
  module Forms
    module SsnField
      def self.included(base)
        base.class_eval do
          attr_reader :ssn, :no_ssn

          def ssn=(new_ssn)
            @ssn = new_ssn.to_s.gsub(/\D/, '') unless new_ssn.blank?
          end

          def no_ssn=(no_ssn)
            @no_ssn = no_ssn
          end
        end
      end
    end
  end
end