# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class terminate(shop) a coverage_selected/coverage_terminated/coverage_termination_pending
    # hbx_enrollment when employment termianted/future terminated sceanrio,
    # more enhancement need to be done to this class to handle various enrollment terminations.
    class Terminate
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment
      # @return [ HbxEnrollment ] hbx_enrollment
      def call(params)
        values            = yield validate(params)
        hbx_enrollment    = yield terminate_employment_term_enrollment(values)

        Success(hbx_enrollment)
      end

      private

      def validate(params)
        return Failure('Missing Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Not a SHOP enrollment.') unless params[:hbx_enrollment].is_shop?
        return Failure("Missing census employee.") unless params[:hbx_enrollment].census_employee

        Success(params)
      end

      def terminate_employment_term_enrollment(params)
        hbx_enrollment = params[:hbx_enrollment]
        census_employee = hbx_enrollment.census_employee
        employment_term_date = census_employee.employment_terminated_on
        return Success(hbx_enrollment) unless employment_term_date.present?
        family = hbx_enrollment.family
        enrollments = family.hbx_enrollments.where(sponsored_benefit_package_id: hbx_enrollment.sponsored_benefit_package_id).enrolled.shop_market
        enrollments.each do |enrollment|
          enrollment.term_or_cancel_enrollment(enrollment, employment_term_date)
        end
        notify = params[:options].present? && params[:options][:notify].present? ? params[:options][:notify] : true
        hbx_enrollment.notify_of_coverage_start(notify)

        Success(hbx_enrollment)
      end
    end
  end
end
