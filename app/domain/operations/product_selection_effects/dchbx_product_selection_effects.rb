# frozen_string_literal: true

module Operations
  module ProductSelectionEffects
    # This class is invoked when a product selection is made.
    # It will execute the side effects of making a product selection, as
    # specific to the DCHBX customer.
    class DchbxProductSelectionEffects
      include Dry::Monads[:result, :do]

      # Invoke the operation.
      # @param opts [Hash] the invocation options
      # @option opts [HbxEnrollment] :enrollment the enrollment the selection
      #   was made against
      # @option opts [Family] :family the family involved in the selection
      # @option opts [BenefitMarkets::Products::Product] :product the selected product
      def self.call(opts = {})
        self.new.call(opts)
      end

      # Invoke the operation.
      # @param opts [Hash] the invocation options
      # @option opts [HbxEnrollment] :enrollment the enrollment the selection
      #   was made against
      # @option opts [Family] :family the family involved in the selection
      # @option opts [BenefitMarkets::Products::Product] :product the selected product
      def call(opts = {})
        enrollment = opts[:enrollment]
        if enrollment.is_shop?
          enrollment.update_existing_shop_coverage
        else
          ::Operations::ProductSelectionEffects::TerminatePreviousSelections.call(opts)
        end

        return Success(:ok) unless enrollment.benefit_group_assignment
        benefit_group_assignment = enrollment.benefit_group_assignment
        benefit_group_assignment.select_coverage if benefit_group_assignment.may_select_coverage?
        benefit_group_assignment.hbx_enrollment = enrollment
        benefit_group_assignment.save
        Success(:ok)
      end
    end
  end
end