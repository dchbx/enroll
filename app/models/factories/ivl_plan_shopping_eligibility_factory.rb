# frozen_string_literal: true

# This factory's scope is just for Plan Shopping.
# This factory specifically deals with the non-persisted
# enrollments that are generated during plan shopping.

module Factories
  class IvlPlanShoppingEligibilityFactory
    include IvlEligibilityFactory

    def initialize(enrollment, effective_on, selected_aptc = nil, product_ids = [])
      raise "Given enrollment object is not a valid enrollment." unless enrollment.is_a?(::HbxEnrollment)

      @enrollment = enrollment
      @family = @enrollment.family
      @effective_on = effective_on
      set_applicable_aptc_attrs(selected_aptc, product_ids) if product_ids.present? && selected_aptc
    end
  end
end
