# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class AddFinancialAssistanceEligibilityDetermination
      send(:include, Dry::Monads[:result, :do])

      def call(params:)
        Success('result')
      end
    end
  end
end
