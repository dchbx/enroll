# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params:)
          values = yield validate(params)
          result = yeild create(values)
          #return application_id
        end

        private

        def validate(params)

        end

        def create(values)

        end
      end
    end
  end
end