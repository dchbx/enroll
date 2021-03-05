# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Operation handles one enrollment at a time.
    # Operation terminates enrollments with aged of dependents and creates new enrollments excluding the aged off dependents.
    # Operation check for date range (enrollment effective..current month) and processes based on the yml settings to determine if the operations should be running annualy/monthly.
    # Operation used to handle enrollment that missed terminating aged of dependents on a enrollment.
    class DependentAgeOff
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment
      # @return [ HbxEnrollment ] hbx_enrollment
      def call(params)
        values            = yield validate(params)
        hbx_enrollment    = yield process_dependent_age_off(values)

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

      def process_dependent_age_off(params)
        hbx_enrollment = params[:hbx_enrollment]
        execute_age_off_for(hbx_enrollment, check_age_off_for_dates(hbx_enrollment))
        Success(hbx_enrollment)
      end

      def check_age_off_for_dates(hbx_enrollment)
        census_employee = hbx_enrollment.census_employee
        term_date = census_employee.employment_terminated_on
        dependent_age_off_dates = (hbx_enrollment.effective_on..(term_date || TimeKeeper.date_of_record).beginning_of_month)
        dependent_age_off_dates.to_a.select {|date| date if date == date.beginning_of_month}
      end

      def age_off_query(hbx_enrollment)
        family = hbx_enrollment.family
        benefit_package = hbx_enrollment.sponsored_benefit_package
        family.hbx_enrollments.where(sponsored_benefit_package_id: benefit_package.id).enrolled.shop_market.all_with_multiple_enrollment_members
      end

      def execute_age_off_for(hbx_enrollment, list_of_dates)
        list_of_dates.each do |dao_date|
          enrollment_query = age_off_query(hbx_enrollment)
          if hbx_enrollment.fehb_profile.present?
            fehb_age_off(dao_date, enrollment_query)
          elsif hbx_enrollment.is_shop?
            shop_age_off(dao_date, enrollment_query)
          end
        end
      end

      def shop_age_off(dao_date, enrollment_query)
        shop_dao = Operations::Shop::DependentAgeOff.new
        shop_dao.call(new_date: dao_date, enrollment_query: enrollment_query)
      end

      def fehb_age_off(dao_date, enrollment)
        fehb_dao = Operations::Fehb::DependentAgeOff.new
        fehb_dao.call(new_date: dao_date, enrollment: enrollment)
      end
    end
  end
end
