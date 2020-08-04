# frozen_string_literal: true

module Operations
  module Ivl
    # This class is invoked when an enrollment is purchased by reporting a SEP
    # and we want to renew this enrollment for next year.
    # Constaint for assisted renewals:
    # Cancel passive renewals before calling this class to be able to passive renew enrollment.

    class RenewOeSepEnrollment
      include Dry::Monads[:result, :do]

      def call(enrollment:)
        renewal_bcp        = yield fetch_renewal_bcp
        current_enrollment = yield validate_for_required_data(enrollment, renewal_bcp)
        tax_household      = yield lookup_for_tax_household(current_enrollment, renewal_bcp)
        aptc_values        = yield fetch_aptc_values(tax_household)

        renew_ivl_enrollment(current_enrollment, tax_household, aptc_values, renewal_bcp)
      end

      private

      def validate_for_required_data(enrollment, renewal_bcp)
        if !enrollment.is_a?(HbxEnrollment)
          Failure('Given object is not a valid enrollment object')
        elsif !enrollment.is_ivl_by_kind?
          Failure('Given enrollment is not IVL by kind')
        elsif !can_renew_enrollment(enrollment, renewal_bcp)
          Failure('There exists active enrollments for given family in the year with renewal_benefit_coverage_period')
        else
          Success(enrollment)
        end
      end

      def fetch_renewal_bcp
        renewal_bcp = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period
        renewal_bcp ? Success(renewal_bcp) : Failure('Unable to find the renewal_benefit_coverage_period')
      end

      def can_renew_enrollment(enrollment, renewal_bcp)
        oeb_object = Enrollments::IndividualMarket::OpenEnrollmentBegin.new
        oeb_object.can_renew_enrollment?(enrollment, enrollment.family, renewal_bcp)
      end

      def lookup_for_tax_household(enrollment, renewal_bcp)
        Success(enrollment.family.active_household.latest_active_thh_with_year(renewal_bcp.start_on.year))
      end

      def fetch_aptc_values(tax_household)
        if tax_household
          Success({applied_percentage: 1,
                   applied_aptc: tax_household.current_max_aptc.to_f,
                   max_aptc: tax_household.current_max_aptc.to_f,
                   csr_amt: tax_household.current_csr_percent_as_integer})
        else
          Success({})
        end
      end

      def renew_ivl_enrollment(enrollment, tax_household, aptc_values, renewal_bcp)
        enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
        enrollment_renewal.enrollment = enrollment
        enrollment_renewal.assisted = tax_household.present? ? true : false
        enrollment_renewal.aptc_values = aptc_values
        enrollment_renewal.renewal_coverage_start = renewal_bcp.start_on
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
