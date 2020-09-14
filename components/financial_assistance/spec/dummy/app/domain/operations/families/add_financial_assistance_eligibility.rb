# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class AddFinancialAssistanceEligibility
      send(:include, Dry::Monads[:result, :do])

      def call(application:)
        Success('result')
      end
    end
  end
end
