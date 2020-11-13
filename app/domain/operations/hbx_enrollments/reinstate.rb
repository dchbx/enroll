# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class reinstates a coverage_canceled/coverage_terminated/
    # coverage_termination_pending hbx_enrollment where end result
    # is a new hbx_enrollment. The effective_period of the newly
    # created hbx_enrollment depends on the aasm_state of the input
    # hbx_enrollment. The aasm_state of the newly created application
    # will be shopping. Currently, this operation does not account for
    # APTC related values yet for IVL cases.
    class Reinstate
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment
      # @return [ HbxEnrollment ] hbx_enrollment
      def call(params)
        values           = yield validate(params)
        @effective_on    = yield fetch_effective_on(values)
        _filtered_values = yield filter(values)
        new_enr          = yield reinstate_hbx_enrollment

        Success(new_enr)
      end

      private

      def validate(params)
        return Failure('Missing Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)

        Success(params)
      end

      def filter(values)
        valid_states_for_reinstatement = ['coverage_terminated', 'coverage_termination_pending', 'coverage_canceled']
        return Failure("Given HbxEnrollment is not in any of the #{valid_states_for_reinstatement} states.") unless valid_states_for_reinstatement.include?(values[:hbx_enrollment].aasm_state)
        init_instance_variables(values)
        return Failure("HbxEnrollment cannot be reinstated. Employer Sponsored Benefits no longer offers the plan/product: #{@reinstate_plan.name}.") unless can_be_reinstated?

        Success(values)
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
          Success(@current_enr.terminated_on.next_day)
        when 'coverage_termination_pending'
          Success(@current_enr.terminated_on.next_day)
        when 'coverage_canceled'
          Success(@current_enr.effective_on)
        else
          Failure("Cannot determine effective_on because of the aasm_state: #{@current_enr.aasm_state}")
        end
      end

      def reinstate_hbx_enrollment
        new_enr = init_hbx_enrollment
        @current_enr.hbx_enrollment_members.each do |member|
          init_hbx_enrollment_member(member, new_enr)
        end
        new_enr.save!
        Success(new_enr)
      end

      def init_hbx_enrollment
        ba_params = @current_enr.attributes.deep_symbolize_keys.slice(:coverage_kind, :enrollment_kind, :kind, :predecessor_enrollment_id)
        ba_params.merge!({aasm_state: 'shopping', effective_on: @effective_on})
        ba_params.merge!(additional_attrs)
        new_enr = HbxEnrollment.new
        new_enr.assign_attributes(ba_params)
        new_enr.family = @current_enr.family
        new_enr.household = @current_enr.family.active_household
        new_enr
      end

      def init_hbx_enrollment_member(current_member, new_enr)
        member_params = current_member.attributes.deep_symbolize_keys.slice(:applicant_id, :is_subscriber)
        member_params.merge!({coverage_start_on: member_coverage_start_date(current_member), eligibility_date: @effective_on})
        new_member = new_enr.hbx_enrollment_members.new
        new_member.assign_attributes(member_params)
      end

      def member_coverage_start_date(current_member)
        if @current_enr.is_shop? && @can_reinstate_under_renewal_py
          @effective_on
        else
          current_member.coverage_start_on || @current_enr.effective_on || @effective_on
        end
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
