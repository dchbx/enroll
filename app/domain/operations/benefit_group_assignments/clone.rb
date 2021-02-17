# frozen_string_literal: true

module Operations
  module BenefitGroupAssignments
    # This class clones a benefit_group_assignment where end
    # result is a new benefit_group_assignment. The end_on
    # of the newly created benefit_group_assignment will be nil
    # Also, the result benefit_group_assignment is a non-persisted object.
    class Clone
      include Dry::Monads[:result, :do]

      # @param [ BenefitGroupAssignment ] benefit_group_assignment
      # @param [ Hash ] options additional attributes for new benefit_group_assignment
      # @return [ BenefitGroupAssignment ] benefit_group_assignment
      def call(params)
        values         = yield validate(params)
        bga_params     = yield construct_params(values)
        bga_entity     = yield build_benefit_group_assignment(bga_params)
        new_bga        = yield clone_benefit_group_assignment(bga_entity)

        Success(new_bga)
      end

      private

      def validate(params)
        return Failure('Missing Keys.') unless params.key?(:benefit_group_assignment) && params.key?(:options)
        return Failure('Not a valid BenefitGroupAssignment object.') unless params[:benefit_group_assignment].is_a?(BenefitGroupAssignment)
        return Failure("Invalid options's value. Should be a Hash.") unless params[:options].is_a?(Hash)

        Success(params)
      end

      def construct_params(values)
        @old_bga = values[:benefit_group_assignment]
        @census_employee = @old_bga.census_employee
        bga_params = @old_bga.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :hbx_enrollment_id, :aasm_state, :coverage_end_on, :end_on,  :is_active, :workflow_state_transitions)
        bga_params.merge!(values[:options])

        Success(bga_params)
      end

      def build_benefit_group_assignment(bga_params)
        Build.new.call(bga_params)
      end

      def clone_benefit_group_assignment(bga_entity)
        new_bga = @census_employee.benefit_group_assignments.new(bga_entity.to_h)
        Success(new_bga)
      end
    end
  end
end
