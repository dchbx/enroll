# frozen_string_literal: true

module Operations
  module Individual
    class CancelRenewalEnrollment
      include Dry::Monads[:result, :do]
      include FloatHelper

      def call(hbx_enrollment:)
        validated_enrollment = yield validate(hbx_enrollment)
        filter_enrollment = yield filter_enrollment(validated_enrollment)
        cancel_renewals = cancel_renewals(filter_enrollment)
        Success(cancel_renewals)
      end

      private

      def validate(enrollment)
        return Failure('Given object is not a valid enrollment object') unless enrollment.is_a?(HbxEnrollment)
        Success(enrollment)
      end

      def filter_enrollment(enrollment)
        return Failure('Given enrollment is not IVL by kind') unless enrollment.is_ivl_by_kind?
        return Failure('Given enrollment is a shopping enrollment by aasm_state') if enrollment.shopping?
        return Failure('Given enrollment not associated with any family') unless enrollment.family?
        return Failure('System is not under open enrollment') unless enrollment.family.is_under_ivl_open_enrollment?
        Success(enrollment)
      end

      def product_matched(enr, enrollment)
        return false unless enr.product.present?
        enr.product_id == enrollment&.product&.renewal_product&.id || enr.product.hios_base_id == enrollment&.product&.renewal_product&.hios_base_id ||
          enr.product.issuer_profile_id == enrollment&.product&.renewal_product&.issuer_profile_id
      end

      def cancel_renewals(enrollment)
        year = HbxProfile.bcp_by_oe_dates.start_on.year
        renewal_enrollments = enrollment.family.hbx_enrollments.by_coverage_kind(enrollment.coverage_kind).by_year(year).show_enrollments_sans_canceled.by_kind(enrollment.kind)
        renewal_enrollments.each do |enr|
          next unless enr&.subscriber&.applicant_id == enrollment&.subscriber&.applicant_id
          next if (enr.hbx_enrollment_members.map(&:applicant_id) - enrollment.hbx_enrollment_members.map(&:applicant_id)).any?
          next if (enrollment.hbx_enrollment_members.map(&:applicant_id) - enr.hbx_enrollment_members.map(&:applicant_id)).any?
          next unless enr.effective_on == enrollment.effective_on.next_year.beginning_of_year
          next unless product_matched(enr, enrollment) || enr.workflow_state_transitions.any?{|wst| wst.to_state == 'auto_renewing'}
          enr.cancel_coverage! if enr.may_cancel_coverage?
        end
      end
    end
  end
end
