# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params:)
          values = yield validate(params)
          result = yield create(values)
        end

        private

        def validate(params)
          result = FinancialAssistance::Validators::ApplicationContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def create(values)
          application = FinancialAssistance::Entities::Application.new(values)

          Success(application)
        end
      end
    end
  end
end