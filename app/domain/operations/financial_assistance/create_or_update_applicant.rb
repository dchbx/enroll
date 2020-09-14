# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    class CreateOrUpdateApplicant
      include Dry::Monads[:result, :do]

      def call(params:)
      end
    end
  end
end
