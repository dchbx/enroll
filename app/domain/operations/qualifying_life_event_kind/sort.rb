# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Sort
      include Dry::Monads[:result, :do]

    end
  end
end
