# frozen_string_literal: true

module FinancialAssistance
  module Entities
    class Application < Dry::Struct
      transform_keys(&:to_sym)


    end
  end
end