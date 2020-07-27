# frozen_string_literal: true

module Operations
  # This class is invoked when a product selection is made.
  # It will consult the configuration settings to select and execute
  # the proper operation for what actions should take place as a
  # side effect of product selection.
  class ExecuteProductSelectionEffects
    include Dry::Monads[:result, :do, :try]

    # Invoke the operation.
    # @param opts [Hash] the invocation options
    # @option opts [HbxEnrollment] :enrollment the enrollment the selection
    #   was made against
    # @option opts [Family] :family the family involved in the selection
    # @option opts [BenefitMarkets::Product] :product the selected product
    def self.call(opts = {})
      self.new.call(opts)
    end

    # Invoke the operation.
    # @param opts [Hash] the invocation options
    # @option opts [HbxEnrollment] :enrollment the enrollment the selection
    #   was made against
    # @option opts [Family] :family the family involved in the selection
    # @option opts [BenefitMarkets::Product] :product the selected product
    def call(opts = {})
      setting_value = yield lookup_setting
      selected_operation = yield create_operation_instance(setting_value.value!)
      selected_operation.value!.call(opts)
    end

    def lookup_setting
      Try do
        Success(
          EnrollRegistry[:product_selection_effects].settings(:operation).item
        )
      end.or(Failure(:product_selection_effect_operation_unspecified))
    end

    def create_operation_instance(klass_name)
      Try do
        Success(
          klass_name.constantize
        )
      end.or(Failure(:product_selection_effect_operation_no_such_class))
    end
  end
end