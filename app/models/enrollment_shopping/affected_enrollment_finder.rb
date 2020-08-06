# frozen_string_literal: true

module EnrollmentShopping
  # Find enrollments that are or have the potential to be affected by a
  # purchase.
  class AffectedEnrollmentFinder

    def for_enrollment(enrollment)
      family = enrollment.family

      family.active_household.hbx_enrollments.show_enrollments_sans_canceled.by_coverage_kind(enrollment.coverage_kind).select do |hbx_enrollment|
        (hbx_enrollment.sponsored_benefit_package&.benefit_application&.id == enrollment.sponsored_benefit_package&.benefit_application&.id) &&
          (hbx_enrollment.active_during?(enrollment.effective_on) || hbx_enrollment.effective_on > enrollment.effective_on) &&
          (hbx_enrollment.id != enrollment.id)
      end
    end
  end
end
