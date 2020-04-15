# frozen_string_literal: true

require 'dry/monads'

module HbxEnrollments
  module Operations
    class Persist
      include Dry::Monads[:result, :do]

      def call(params, edi)
        new_enrollment              = yield create(params, edi)
        _predecessor_enrollment     = yield predecessor_enrollment(new_enrollment)
        _update_roaster             = yield update_roaster(new_enrollment)
        Success(new_enrollment)
      end

      private

      def create(params, edi)
        new_enrollment = HbxEnrollment.new(params.to_h)
        new_enrollment.reterm_coverage! if new_enrollment.may_reterm_coverage?
        result = if new_enrollment.effective_on == new_enrollment.terminated_on && new_enrollment.may_cancel_coverage?
                   new_enrollment.cancel_coverage!
                 elsif new_enrollment.may_terminate_coverage?
                   new_enrollment.terminate_coverage!
                 end
        new_enrollment.notify_enrollment_cancel_or_termination_event(edi) if result
        Success(new_enrollment)
      end

      def predecessor_enrollment(policy)
        parent_enrollment = policy.parent_enrollment
        parent_enrollment.reterm_coverage! if parent_enrollment.may_reterm_coverage?
        Success(parent_enrollment)
      end

      def update_roaster(new_enrollment)
        employee = new_enrollment.census_employee
        employee.update_attributes(coverage_terminated_on: new_enrollment.terminated_on) if employee.present? && employee.employment_terminated?
        Success(employee)
      end
    end
  end
end