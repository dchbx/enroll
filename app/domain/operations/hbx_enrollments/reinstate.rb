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
        valid_states_for_reinstatement = ['coverage_terminated', 'coverage_termination_pending', 'coverage_canceled']
        return Failure("Given HbxEnrollment is not in any of the #{valid_states_for_reinstatement} states.") unless valid_states_for_reinstatement.include?(params[:hbx_enrollment].aasm_state)
        return Failure('Overlapping coverage exists for this family in current year.') if overlapping_enrollment_exists?(params)
        init_instance_variables(params)
        return Failure("HbxEnrollment cannot be reinstated. Employer Sponsored Benefits no longer offers the plan/product: #{@reinstate_plan.name}.") unless can_be_reinstated?

        Success(params)
      end

      def overlapping_enrollment_exists?(params)
        @effective_on = fetch_effective_on(params)
        current_enr = params[:hbx_enrollment]
        query_criteria = {:aasm_state.nin => ['shopping', 'coverage_canceled'], :_id.ne => current_enr.id, kind: current_enr.kind, coverage_kind: current_enr.coverage_kind}
        valid_enrs = current_enr.family.hbx_enrollments.where(query_criteria)
        valid_enrs.any?{|ba| ba.effective_on >= @effective_on && ba.effective_on.year == @effective_on.year}
      end

      def init_instance_variables(values)
        @current_enr = values[:hbx_enrollment]
        return unless @current_enr.is_shop?

        benefit_application = @current_enr.sponsored_benefit_package.benefit_application
        @census_employee = @current_enr.benefit_group_assignment.census_employee
        @can_reinstate_under_renewal_py = @effective_on > benefit_application.end_on
        @renewal_benefit_application = benefit_application.benefit_sponsorship.benefit_applications.renewing.published_benefit_applications_by_date(@effective_on).first
        renewal_bga = fetch_renewal_bga
        @reinstate_plan = @can_reinstate_under_renewal_py ? @current_enr.product.renewal_product : @current_enr.product
        @reinstate_bga_id = @can_reinstate_under_renewal_py ? renewal_bga.id : @current_enr.benefit_group_assignment_id
        @reinstate_sbp = @can_reinstate_under_renewal_py ? renewal_bga.benefit_group : @current_enr.sponsored_benefit_package
        @reinstate_sb = @current_enr.is_health_enrollment? ? @reinstate_sbp.health_sponsored_benefit : @reinstate_sbp.dental_sponsored_benefit
        @reinstate_rating_area = @can_reinstate_under_renewal_py ? renewal_bga.benefit_application.recorded_rating_area_id : @current_enr.rating_area_id
      end

      def can_be_reinstated?
        return true unless @can_reinstate_under_renewal_py
        @reinstate_sb.products(@effective_on).map(&:_id).include?(@reinstate_plan.id)
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
        clone_result = Clone.new.call({hbx_enrollment: values[:hbx_enrollment], effective_on: @effective_on, options: additional_attrs})
        return clone_result if clone_result.failure?
        new_enrollment = clone_result.success
        update_member_coverage_dates(new_enrollment.hbx_enrollment_members)
        new_enrollment.save!
        Success(new_enrollment)
      end

      def update_member_coverage_dates(members)
        members.each do |member|
          member.eligibility_date = @effective_on
          member.coverage_start_on = member_coverage_start_date(member)
        end
      end

      def member_coverage_start_date(enrollment_member)
        if @current_enr.is_shop? && @can_reinstate_under_renewal_py
          @effective_on
        else
          enrollment_member.coverage_start_on || @current_enr.effective_on || @effective_on
        end
      end

      def reinstate_hbx_enrollment(new_enrollment)
        return Failure('Cannot transition to state coverage_reinstated on event reinstate_coverage.') unless new_enrollment.may_reinstate_coverage?

        new_enrollment.reinstate_coverage!
        return Failure('Cannot transition to state coverage_selected on event begin_coverage.') unless new_enrollment.may_begin_coverage?

        new_enrollment.begin_coverage!
        Success(new_enrollment)
      end

      def fetch_renewal_bga
        assignment = @census_employee.renewal_benefit_group_assignment
        if assignment.blank?
          @census_employee.save if @census_employee.active_benefit_group_assignment.blank?
          assignment = @census_employee.published_benefit_group_assignment if @renewal_benefit_application == @census_employee.published_benefit_group_assignment.benefit_application
        end
        assignment
      end

      def additional_attrs
        if @current_enr.is_shop?
          shop_attributes
        elsif @current_enr.is_ivl_by_kind?
          ivl_attributes
        end
      end

      def shop_attributes
        {employee_role_id: @current_enr.employee_role_id,
         benefit_group_assignment_id: @reinstate_bga_id,
         sponsored_benefit_package_id: @reinstate_sbp.id,
         sponsored_benefit_id: @reinstate_sb.id,
         benefit_sponsorship_id: @current_enr.benefit_sponsorship_id,
         product_id: @reinstate_plan.id,
         rating_area_id: @reinstate_rating_area,
         issuer_profile_id: @reinstate_plan.issuer_profile_id}
      end

      def ivl_attributes
        {product_id: @current_enr.product_id,
         consumer_role_id: @current_enr.consumer_role_id}
      end
    end
  end
end
