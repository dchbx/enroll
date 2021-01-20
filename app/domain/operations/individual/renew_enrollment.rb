# frozen_string_literal: true

module Operations
  module Individual
    # This class is invoked when we want to generate a passive renewal for an active enrollment.
    # It will validate the incoming enrollment if it can be renewed and calls a different class
    # to generate the renewal enrollment.
    # It will renew HbxEnrollments that are effectuated(by aasm state).
    # It will renew an HbxEnrollment with a retroactive effective date.
    # It will renew an HbxEnrollment for an effective date that's not first day of month.
    # It will renew both health and dental enrollments.

    # For assisted renewals:
    # It will fetch eligibility values from the DB for renewing enrollment.
    # The applied aptc is sum of member aptcs calculated based on the new enrollment members(covers HbxEnrollmentMembers change).
    # If none of the HbxEnrollmentMembers are eligible for APTC, then no aptc will be applied on to the HbxEnrollment.
    # If any enrollment member who is child/ward/foster_child/adopted_child to primary and is aged equal or above 26,
    # then the member will be dropped from the renewal enrollment. Also, the renewal enrollment will be in 'coverage_selected' state.
    # Case where ehb_premium is less than the selected aptc, then the aptc equals to ehb_premium will be applied on to enrollment.
    # Case where ehb_premium is greater than the selected aptc, then the selected aptc will be applied on to enrollment.
    # Case where one of the enrollment members are not is_ia_eligible, then the renewal_product will be selected and not a CSR product.
    # The default aptc to be applied on to the enrollment is 85% of applicable aptc for the cases where current enrollment is not assisted.
    # If the current enrollment is assisted(has applied aptc), then the same percentage of aptc will be applied to the renewing enrollment.
    class RenewEnrollment
      include Dry::Monads[:result, :do]
      include FloatHelper

      # @param [ HbxEnrollment ] hbx_enrollment Enrollment that needs to be renewed.
      # @param [ Date ] effective_on Effective Date of the renewal enrollment.
      # @return [ HbxEnrollment ] renewal_enrollment.
      def call(hbx_enrollment:, effective_on:)
        validated_enrollment = yield validate(hbx_enrollment, effective_on)
        eligibility_values   = yield fetch_eligibility_values(validated_enrollment, effective_on)
        renewal_enrollment   = yield renew_enrollment(validated_enrollment, effective_on, eligibility_values)

        Success(renewal_enrollment)
      end

      private

      def validate(enrollment, effective_on)
        return Failure('Given object is not a valid enrollment object') unless enrollment.is_a?(HbxEnrollment)
        return Failure('Given enrollment is not IVL by kind') unless enrollment.is_ivl_by_kind?
        return Failure('Given enrollment is a shopping enrollment by aasm_state') if enrollment.shopping?
        return Failure('There exists active enrollments for the subscriber in the year with given effective_on') unless enrollment.can_renew_coverage?(effective_on)

        Success(enrollment)
      end

      def fetch_eligibility_values(enrollment, effective_on)
        return Success({}) unless enrollment.is_health_enrollment?

        family = enrollment.family
        tax_household = family.active_household.latest_active_thh_with_year(effective_on.year)
        if tax_household
          max_aptc = tax_household.total_aptc_available_amount_for_enrollment(enrollment, effective_on)
          default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
          applied_percentage = enrollment.elected_aptc_pct > 0 ? enrollment.elected_aptc_pct : default_percentage
          applied_aptc = float_fix(max_aptc * applied_percentage)
          data = { applied_percentage: applied_percentage,
                   applied_aptc: applied_aptc,
                   max_aptc: max_aptc,
                   csr_amt: tax_household.current_csr_percent_as_integer }
        end

        Success(data || {})
      end

      def renew_enrollment(enrollment, effective_on, eligibility_values)
        enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
        enrollment_renewal.enrollment = enrollment
        enrollment_renewal.assisted = eligibility_values.present? ? true : false
        enrollment_renewal.aptc_values = eligibility_values
        enrollment_renewal.renewal_coverage_start = effective_on
        renewed_enrollment = enrollment_renewal.renew
        if renewed_enrollment.is_a?(HbxEnrollment)
          Success(renewed_enrollment)
        else
          Failure('Unable to renew the enrollment')
        end
      end
    end
  end
end
