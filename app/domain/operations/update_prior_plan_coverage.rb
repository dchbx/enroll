# frozen_string_literal: true

module Operations
  # This class is invoked when a product selection is made.
  # It will execute the side effects of making a product selection, as
  # specific to the DCHBX customer.
  class UpdatePriorPlanCoverage
    include Dry::Monads[:result, :do, :try]

    # Invoke the operation.
    # @param opts [@enrollment] the invocation options
    def self.call(opts)
      self.new.call(opts)
    end

    # Invoke the operation.
    # @param opts [@enrollment] the invocation options
    def call(opts)
      enrollment = opts[:enrollment]
      return nil unless enrollment.is_shop?
      term_or_expired_enrollment = yield transition_current_enrollment(enrollment)
      result = update_prior_plan_coverage(term_or_expired_enrollment)

      return result if result
      Success(:ok)
    end

    private

    def transition_current_enrollment(enrollment)
      enrollment_benefit_application = enrollment.sponsored_benefit_package.benefit_application
      if enrollment_benefit_application.terminated?
        enrollment.term_or_cancel_enrollment(enrollment, enrollment_benefit_application.end_on, enrollment_benefit_application.termination_reason)
      elsif enrollment_benefit_application.expired?
        enrollment.expire_coverage!
      end
      Success(enrollment)
    end

    def update_prior_plan_coverage(enrollment)
      sep = enrollment.special_enrollment_period
      return nil if sep.blank?
      return nil unless sep.coverage_renewal_flag
      enrollment_benefit_application = enrollment.sponsored_benefit_package.benefit_application
      return nil if enrollment_benefit_application.active? || enrollment_benefit_application.termination_pending?
      @benefit_applications = fetch_future_benefit_applications(enrollment)
      return if @benefit_applications.empty?
      renew_coverage(enrollment)
    end

    def renew_coverage(enrollment)
      @enrollment = enrollment
      census_employee = @enrollment.employee_role.census_employee
      @benefit_applications.each do |ba|
        next unless continuous_py_exists?(@enrollment)
        cancel_renewal_enrollments(ba, @enrollment)
        assignment = fetch_benefit_group_assignment(ba, census_employee)
        next if assignment.blank?
        next if is_employee_in_term_pending?(@enrollment, assignment)
        renewal_enrollment = @enrollment.renew_benefit(assignment.benefit_package)
        next if renewal_enrollment.blank?
        result = transition_enrollment(renewal_enrollment, ba)
        @enrollment = result.success
      rescue StandardError => e
        Rails.logger.error { "Error renewing coverage for employee #{enrollment.census_employee.full_name}'s due to #{e.backtrace}" }
      end
      @enrollment
    end

    def fetch_benefit_group_assignment(benefit_application, census_employee)
      benefit_package_ids = benefit_application.benefit_packages.map(&:id)
      census_employee.benefit_group_assignments.detect { |benefit_group_assignment| benefit_package_ids.include?(benefit_group_assignment.benefit_package.id) && benefit_group_assignment.is_active?(benefit_application.end_on) }
    end

    def cancel_renewal_enrollments(benefit_application, enrollment)
      hbx_enrollments = enrollment.enrollments_for(benefit_application)
      hbx_enrollments.each{|en| en.cancel_coverage! if en.may_cancel_coverage? }
    end

    def transition_enrollment(enrollment, benefit_application)
      enrollment.begin_coverage! if TimeKeeper.date_of_record >= benefit_application.start_on && enrollment.may_begin_coverage?
      Success(enrollment)
    end

    def continuous_py_exists?(enrollment)
      enrollment_benefit_application = enrollment.sponsored_benefit_package.benefit_application
      enrollment.employer_profile.benefit_applications.where(:"effective_period.min" => enrollment_benefit_application.end_on.next_day, :aasm_state.in => BenefitSponsors::BenefitApplications::BenefitApplication::ACTIVE_AND_TERMINATED_STATES).present?
    end

    def fetch_future_benefit_applications(enrollment)
      enrollment.employer_profile.benefit_applications.future_effective_date(enrollment.effective_on).where(:aasm_state.in => BenefitSponsors::BenefitApplications::BenefitApplication::APPPROVED_AND_TERMINATED_STATES)
    end

    def is_employee_in_term_pending?(enrollment, assignment)
      census_employee = enrollment.census_employee
      return false if census_employee.employment_terminated_on.blank?
      return false if census_employee.is_cobra_status?

      effective_period = assignment.benefit_package.effective_period
      census_employee.census_employee.employment_terminated_on <= effective_period.max
    end
  end
end
