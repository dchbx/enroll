module Admin
  module QleKinds
    class DeactivateRequest
      extend Dry::Initializer

      # TODO: Need to make sure this is a date following certain business rules
      option :end_on, Dry::Types['coercible.string'], optional: true
    end
  end
end