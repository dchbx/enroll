# frozen_string_literal: true

module Operations
  module ProductSelectionEffects
    # This class is invoked when a product selection is made.
    # It will execute the side effects of making a product selection, as
    # specific to the DCHBX customer.
    class DchbxProductSelectionEffects
      include Dry::Monads[:result, :do]

      # Invoke the operation.
      # @param opts [Entities::ProductSelection] the invocation options
      def self.call(opts = {})
        self.new.call(opts)
      end

      # Invoke the operation.
      # @param opts [Entities::ProductSelection] the invocation options
      def call(opts = {})
        enrollment = opts.enrollment
        if enrollment.is_shop?
          enrollment.update_existing_shop_coverage
        else
          ::Operations::ProductSelectionEffects::TerminatePreviousSelections.call(opts)
        end

        if enrollment.benefit_group_assignment
          benefit_group_assignment = enrollment.benefit_group_assignment
          benefit_group_assignment.select_coverage if benefit_group_assignment.may_select_coverage?
          benefit_group_assignment.hbx_enrollment = enrollment
          benefit_group_assignment.save
        end

        try_to_renew = renew_ivl_if_is_open_enrollment(enrollment)
        return try_to_renew if try_to_renew
        Success(:ok)
      end

      def renew_ivl_if_is_open_enrollment(enrollment)
        return nil if enrollment.is_shop?
        bp = BenefitPackage.find(enrollment.benefit_package_id)
        bcp = bp.benefit_coverage_period
        return nil unless in_open_enrollment_before_plan_year_start?(bcp)
        sbcp = bcp.successor
        Operations::Individual::RenewEnrollment.new.call(
          hbx_enrollment: enrollment,
          effective_on: sbcp.start_on
        )
      end

      def in_open_enrollment_before_plan_year_start?(benefit_coverage_period)
        current_date = TimeKeeper.date_of_record
        next_coverage_period = benefit_coverage_period.successor
        return false unless next_coverage_period
        return false if current_date.year >= next_coverage_period.start_on.year
        (current_date >= next_coverage_period.open_enrollment_start_on) &&
          (current_date <= next_coverage_period.open_enrollment_end_on)
      end
    end
  end
end