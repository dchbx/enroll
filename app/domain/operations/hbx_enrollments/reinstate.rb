# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class reinstates a coverage_canceled/coverage_terminated/
    # coverage_termination_pending hbx_enrollment where end result
    # is a new hbx_enrollment. The effective_period of the newly
    # created hbx_enrollment depends on the aasm_state of the input
    # hbx_enrollment. The aasm_state of the newly created hbx_enrollment
    # will be coverage_selected. Currently, this operation supports SHOP
    # enrollments only does not account for IVL cases.
    class Reinstate
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment
      # @return [ HbxEnrollment ] hbx_enrollment
      def call(params)
        values           = yield validate(params)
        new_enr          = yield new_hbx_enrollment(values)
        hbx_enrollment   = yield reinstate_hbx_enrollment(new_enr)

        Success(hbx_enrollment)
      end

      private

      def validate(params)
        return Failure('Missing Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Not a SHOP enrollment.') unless params[:hbx_enrollment].is_shop?
        return Failure('Given HbxEnrollment is not in any of the valid states for reinstatement states.') unless valid_by_states?(params[:hbx_enrollment])
        return Failure('Overlapping coverage exists for this family in current year.') if overlapping_enrollment_exists?(params)
        return Failure("Active Benefit Group Assignment does not exist for the effective_on: #{@effective_on}") unless active_bga_exists?

        Success(params)
      end

      def valid_by_states?(enrollment)
        aasm_state = enrollment.aasm_state
        return true if ['coverage_terminated', 'coverage_termination_pending'].include?(aasm_state)
        aasm_state == 'coverage_canceled' && enrollment.terminate_reason == 'retroactive_canceled'
      end

      def active_bga_exists?
        @bga = @current_enr.census_employee.benefit_group_assignments.where(:'$or' => [{:start_on.gte => @effective_on, :end_on.lte => @effective_on},
                                                                                       {:start_on.gte => @effective_on, end_on: nil}]).first
      end

      def overlapping_enrollment_exists?(params)
        @effective_on = fetch_effective_on(params)
        current_enr = params[:hbx_enrollment]
        # Same Employer, same Kind, same Coverage Kind and same sponsored_benefit_package_id.
        query_criteria = {:aasm_state.nin => ['shopping', 'coverage_canceled'],
                          :_id.ne => current_enr.id,
                          kind: current_enr.kind,
                          coverage_kind: current_enr.coverage_kind,
                          sponsored_benefit_package_id: current_enr.sponsored_benefit_package_id,
                          employee_role_id: current_enr.employee_role_id}
        valid_enrs = current_enr.family.hbx_enrollments.where(query_criteria)
        valid_enrs.any?{|ba| ba.effective_on >= @effective_on && ba.effective_on.year == @effective_on.year}
      end

      def fetch_effective_on(params)
        @current_enr = params[:hbx_enrollment]
        case @current_enr.aasm_state
        when 'coverage_terminated'
          @current_enr.terminated_on.next_day
        when 'coverage_termination_pending'
          @current_enr.terminated_on.next_day
        when 'coverage_canceled'
          @current_enr.effective_on
        end
      end

      def new_hbx_enrollment(values)
        clone_result = Clone.new.call({hbx_enrollment: values[:hbx_enrollment], effective_on: @effective_on, options: additional_params})
        return clone_result if clone_result.failure?
        new_enrollment = clone_result.success
        update_member_coverage_dates(new_enrollment.hbx_enrollment_members)
        new_enrollment.save!
        Success(new_enrollment)
      end

      def additional_params
        attrs = {benefit_group_assignment_id: @bga.id, sponsored_benefit_package_id: @bga.benefit_package_id}
        if @current_enr.is_health_enrollment?
          attrs.merge({sponsored_benefit_id: @bga.benefit_package.health_sponsored_benefit.id})
        else
          attrs.merge({sponsored_benefit_id: @bga.benefit_package.dental_sponsored_benefit.id})
        end
      end

      def update_member_coverage_dates(members)
        members.each do |member|
          member.eligibility_date = @effective_on
          member.coverage_start_on = member.coverage_start_on || @current_enr.effective_on
        end
      end

      def reinstate_hbx_enrollment(new_enrollment)
        return Failure('Cannot transition to state coverage_reinstated on event reinstate_coverage.') unless new_enrollment.may_reinstate_coverage?

        new_enrollment.reinstate_coverage!
        if @current_enr.is_waived?
          return Failure('Cannot transition to state inactive on event waive_coverage.') unless new_enrollment.may_waive_coverage?
          new_enrollment.waive_coverage!
        else
          return Failure('Cannot transition to state coverage_selected on event begin_coverage.') unless new_enrollment.may_begin_coverage?
          new_enrollment.begin_coverage!
        end

        Success(new_enrollment)
      end
    end
  end
end
