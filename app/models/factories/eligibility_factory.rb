# frozen_string_literal: true

# This factory can be used for all ivl pdc eligibility related projects.
# Currently Applied: Passive Renewals.
# Future Applicable locations: Plan Shopping Controller, APTC tool, Self Service.
module Factories
  class EligibilityFactory
    include IvlEligibilityFactory

    def initialize(enrollment_id, effective_on, selected_aptc = nil, product_ids = [], excluding_enrollment_id = nil)
      @enrollment = HbxEnrollment.where(id: enrollment_id.to_s).first
      raise "Cannot find a valid enrollment with given enrollment id" unless @enrollment

      @family = @enrollment.family
      @excluding_enrollment_id = excluding_enrollment_id
      @effective_on = effective_on
      set_applicable_aptc_attrs(selected_aptc, product_ids) if product_ids.present? && selected_aptc
    end
  end
end
