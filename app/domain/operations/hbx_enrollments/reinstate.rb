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
        _enrollment      = yield age_off_dependents(hbx_enrollment)
        Success(hbx_enrollment)
      end

      private

      def validate(params)
        return Failure('Missing Key.') unless params.key?(:hbx_enrollment)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Not a SHOP enrollment.') unless params[:hbx_enrollment].is_shop?
        return Failure('Given HbxEnrollment is not in any of the valid states for reinstatement states.') unless valid_by_states?(params[:hbx_enrollment])
        return Failure("Active Benefit Group Assignment does not exist for the effective_on: #{@effective_on}") unless active_bga_exists?(params)
        return Failure('Overlapping coverage exists for this family in current year.') if overlapping_enrollment_exists?

        Success(params)
      end

      def valid_by_states?(enrollment)
        aasm_state = enrollment.aasm_state
        return true if ['coverage_terminated', 'coverage_termination_pending'].include?(aasm_state)
        aasm_state == 'coverage_canceled' && enrollment.terminate_reason == 'retroactive_canceled'
      end

      def active_bga_exists?(params)
        @effective_on = fetch_effective_on(params)
        @bga = @current_enr.census_employee.benefit_group_assignments.where(:'$or' => [{:start_on.gte => @effective_on, :end_on.lte => @effective_on},
                                                                                       {:start_on.gte => @effective_on, end_on: nil}]).first
      end

      def overlapping_enrollment_exists?
        # Same Employer, same Kind, same Coverage Kind and same sponsored_benefit_package_id.
        query_criteria = {:aasm_state.nin => ['shopping', 'coverage_canceled'],
                          :_id.ne => @current_enr.id,
                          kind: @current_enr.kind,
                          coverage_kind: @current_enr.coverage_kind,
                          sponsored_benefit_package_id: @bga.benefit_package_id,
                          employee_role_id: @current_enr.employee_role_id,
                          effective_on: {"$gte": @bga.benefit_package.start_on.to_date, "$lte": @bga.benefit_package.end_on.to_date}}
        @current_enr.family.hbx_enrollments.where(query_criteria).any?
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

      def age_off_dependents(new_enrollment)
        dependent_age_off_enrollment(new_enrollment, reinstate_dates(new_enrollment))
        Success(new_enrollment)
      end

      def reinstate_dates(new_enrollment)
        dependent_age_off_dates = (new_enrollment.effective_on..TimeKeeper.date_of_record.beginning_of_month)
        dependent_age_off_dates.to_a.select {|date| date if date == date.beginning_of_month}
      end

      def dependent_age_off_enrollment(new_enrollment, list_of_dates)
        @depenent_age_off_enr = new_enrollment
        list_of_dates.each do |dao_date|
          family = new_enrollment.family
          enrollment_query = family.hbx_enrollments.where(sponsored_benefit_package_id: new_enrollment.sponsored_benefit_package_id).enrolled.shop_market.all_with_multiple_enrollment_members
          if new_enrollment.fehb_profile.present?
            result = fehb_reinstate_enrollment(dao_date, @depenent_age_off_enr)
            @depenent_age_off_enr = result.nil? ? @depenent_age_off_enr : result
          elsif new_enrollment.is_shop?
            shop_reinstate_enrollment(dao_date, enrollment_query)
          end
        end
      end

      def shop_reinstate_enrollment(dao_date, enrollment_query)
        shop_dao = Operations::Shop::DependentAgeOff.new
        if ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:period).item == :monthly
          shop_dao.call(new_date: dao_date, enrollment_query: enrollment_query)
        elsif dao_date.strftime("%m/%d") == Date.today.beginning_of_year.strftime("%m/%d") && ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:period).item == :annual
          shop_dao.call(new_date: dao_date, enrollment_query: enrollment_query)
        end
      end

      def fehb_reinstate_enrollment(dao_date, enrollment)
        fehb_dao = Operations::Fehb::DependentAgeOff.new
        if ::EnrollRegistry[:aca_fehb_dependent_age_off].settings(:period).item == :monthly
          fehb_dao.call(new_date: dao_date, enrollment: enrollment)
        elsif ::EnrollRegistry[:aca_fehb_dependent_age_off].settings(:period).item == :annual
          fehb_dao.call(new_date: dao_date, enrollment: enrollment) if dao_date.strftime("%m/%d") == Date.today.beginning_of_year.strftime("%m/%d")
        end
      end
    end
  end
end
