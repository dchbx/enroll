# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class ConsumerRoleCreateOrUpdate
      include Dry::Monads[:result, :do]
    end
  end
end

