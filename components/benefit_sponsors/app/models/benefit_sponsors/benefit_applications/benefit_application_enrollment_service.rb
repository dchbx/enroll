module BenefitSponsors
  class BenefitApplications::BenefitApplicationEnrollmentService
    include Config::AcaModelConcern

    attr_reader   :benefit_application, :business_policy, :errors, :messages

    def initialize(benefit_application)
      @benefit_application = benefit_application
      @errors = []
      @messages = {}
    end

    def renew_application(async_workflow_id = nil)
      if business_policy_satisfied_for?(:renew_benefit_application)
        renewal_application = benefit_application.renew(async_workflow_id)
        renewal_application.save
        [true, renewal_application, business_policy.success_results]
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    def revert_application
      if benefit_application.may_revert_application?
        benefit_application.revert_application!
        
        [true, benefit_application, {}]
      else
        [false, benefit_application]
      end
    end

    def submit_application
      if benefit_application.may_approve_application?
        if is_application_eligible?
          if business_policy_satisfied_for?(:submit_benefit_application)
            benefit_application.approve_application!
            oe_period = benefit_application.open_enrollment_period

            if today >= oe_period.begin
              benefit_application.begin_open_enrollment!
              benefit_application.update(open_enrollment_period: (today..oe_period.end))
            end

            [true, benefit_application, application_warnings]
          else
            [false, benefit_application, business_policy.fail_results]
          end
        else
          [false, benefit_application, application_eligibility_warnings]
        end
      else
        errors = application_errors.merge(open_enrollment_date_errors)
        [false, benefit_application, errors]
      end
    end

    def force_submit_application_with_eligibility_errors
      unless business_policy_satisfied_for?(:submit_benefit_application)
        if benefit_application.is_renewing?
          if business_policy.fail_results.keys.include?(:employer_primary_office_location)
            benefit_application.submit_for_review! if benefit_application.may_submit_for_review?
          end
        elsif business_policy.fail_results.keys.include?(:employer_primary_office_location) || business_policy.fail_results.keys.include?(:benefit_application_fte_count)
          benefit_application.submit_for_review! if benefit_application.may_submit_for_review?
        end
      end
    end

    def force_submit_application
      if business_policy_satisfied_for?(:force_submit_benefit_application) && is_application_eligible?
        if benefit_application.may_approve_application?
          benefit_application.auto_approve_application!
          
          if today >= benefit_application.open_enrollment_period.begin
            benefit_application.begin_open_enrollment!
            @messages['notice'] = 'Employer(s) Plan Year was successfully published.'
          else
            raise 'Employer(s) Plan Year date has not matched.'
          end
        else
          @messages['notice'] = 'Employer(s) Plan Year could not be processed.'
        end
      elsif benefit_application.may_submit_for_review?
        benefit_application.submit_for_review!
        @messages['notice'] = 'Employer(s) Plan Year was successfully submitted for review.'
        @messages['warnings'] = force_publish_warnings unless force_publish_warnings.empty?
      else
        @messages['notice'] = 'Employer(s) Plan Year could not be processed.'
        @messages['warnings'] = force_publish_warnings unless force_publish_warnings.empty?
      end
    rescue => e
      @errors = [e.message]
    end

    def may_force_submit_application?
      if business_policy_satisfied_for?(:force_submit_benefit_application) && is_application_eligible?
        true
      else
        @messages['warnings'] = force_publish_warnings #business_policy.fail_results.merge(application_eligibility_warnings)
        false
      end
    end

    def begin_open_enrollment
      open_enrollment_begin = benefit_application.open_enrollment_period.begin

      if business_policy_satisfied_for?(:begin_open_enrollment)
        if today >= open_enrollment_begin
          # benefit_application.validate_sponsor_market_policy
          # return false unless benefit_application.is_valid?
          # business_policy.assert(benefit_application)
          # if business_policy.is_satisfied?(benefit_application)

          if benefit_application.may_begin_open_enrollment?
            benefit_application.begin_open_enrollment!
          else
            benefit_application.errors.add(:base, "State transition failed")
            return false
          end
        end
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    def end_open_enrollment(end_date = nil)
      if benefit_application.may_end_open_enrollment?
        benefit_application.update(open_enrollment_period: benefit_application.open_enrollment_period.min..end_date) if end_date.present?
        benefit_application.end_open_enrollment!

        if business_policy_satisfied_for?(:end_open_enrollment)
          benefit_application.approve_enrollment_eligiblity! if benefit_application.is_renewing? && benefit_application.may_approve_enrollment_eligiblity?
          calculate_pricing_determinations(benefit_application)
          [true, benefit_application, business_policy.success_results]
        else
          benefit_application.deny_enrollment_eligiblity! if benefit_application.may_deny_enrollment_eligiblity?
          benefit_application.benefit_packages.map(&:cancel_member_benefits) unless Settings.aca.shop_market.auto_cancel_ineligible
          [false, benefit_application, business_policy.fail_results]
        end
      end
    end

    def begin_benefit
      if business_policy_satisfied_for?(:begin_benefit)
        if benefit_application.may_activate_enrollment?
          benefit_application.activate_enrollment!
        else
          raise StandardError, "Benefit begin state transition failed"
        end
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    def mark_initial_ineligible
      raise StandardError, "Benefit ineligible state transition failed" unless benefit_application.may_deny_enrollment_eligiblity?

      benefit_application.deny_enrollment_eligiblity!
    end

    def cancel(notify_trading_partner = false)
      if business_policy_satisfied_for?(:cancel_benefit)
        if benefit_application.may_cancel?
          benefit_application.cancel!(notify_trading_partner)
        else
          raise StandardError, "Benefit cancel state transition failed"
        end
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    def end_benefit
      if business_policy_satisfied_for?(:end_benefit)
        if benefit_application.may_expire?
          benefit_application.expire!
        else
          raise StandardError, "Benefit expire state transition failed"
        end
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    def terminate(end_on, termination_date, termination_kind, termination_reason, notify_trading_partner = false)
      result, errors = validate_benefit_application_termination_date(end_on, termination_kind)
      if result
        if business_policy_satisfied_for?(:terminate_benefit)
          if benefit_application.may_terminate_enrollment?
            updated_dates = benefit_application.effective_period.min.to_date..end_on
            benefit_application.update_attributes!(:effective_period => updated_dates, :terminated_on => termination_date, termination_kind: termination_kind, termination_reason: termination_reason)
            benefit_application.terminate_enrollment!(notify_trading_partner)
          end
        else
          [false, benefit_application, business_policy.fail_results]
        end
      else
        [false, benefit_application, errors]
      end
    end

    def schedule_termination(end_on, termination_date, termination_kind, termination_reason, notify_trading_partner = false)
      result, errors = validate_benefit_application_termination_date(end_on, termination_kind)
      if result
        if business_policy_satisfied_for?(:terminate_benefit)
          if benefit_application.may_schedule_enrollment_termination?
            updated_dates = benefit_application.effective_period.min.to_date..end_on
            benefit_application.update_attributes!(:effective_period => updated_dates, :terminated_on => termination_date, termination_kind: termination_kind, termination_reason: termination_reason)
            benefit_application.schedule_enrollment_termination!(notify_trading_partner)
          end
        else
          [false, benefit_application, business_policy.fail_results]
        end
      else
        [false, benefit_application, errors]
      end
    end

    # validate :open_enrollment_date_checks
    ## Trigger events can be dates or from UI
    def open_enrollments_past_end_on(date = TimeKeeper.date_of_record)
      # query all benefit_applications in OE state with benefit_application.open_enrollment_period.max < date
      @benefit_applications = BenefitSponsors::BenefitApplications::BenefitApplication.by_open_enrollment_end_date
      @benefit_applications.each do |application|
        if application && application.may_advance_date?
          application.advance_date!
        end
      end
    end

    # Replace method body to run against business policy
    def is_application_valid?
      application_errors.blank?
    end

    def is_application_eligible?
      application_eligibility_warnings.blank?
    end

    def application_warnings
      unless non_owner_employee_present?
        {
          base: "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?"
        }
      end
    end

    def open_enrollment_date_errors
      {}
    end

    def cancel_open_enrollment(benefit_application)
    end

    # Exempt exception handling situation
    def extend_open_enrollment(new_end_date = TimeKeeper.date_of_record)
      if business_policy_satisfied_for?(:extend_open_enrollment)
        if benefit_application.may_extend_open_enrollment?
          benefit_application.update(:open_enrollment_period => benefit_application.open_enrollment_period.min..new_end_date)
          benefit_application.extend_open_enrollment!
        end

        [true, benefit_application, business_policy.success_results]
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    # Exempt exception handling situation
    def retroactive_open_enrollment(benefit_application)

    end

    def reinstate
    end

    def benefit_sponsorship
      return @benefit_sponsorship if defined? @benefit_sponsorship
      @benefit_sponsorship = benefit_application.benefit_sponsorship
    end

    def filter_active_enrollments_by_date(date)
      enrollment_proxies = BenefitApplications::BenefitApplicationEnrollmentsQuery.new(benefit_application).call(::HbxEnrollment, date)
      return [] if (enrollment_proxies.count > 100)
      enrollment_proxies.map do |ep|
        OpenStruct.new(ep)
      end
    end

    def hbx_enrollments_by_month(date)
      end_date = (benefit_application.effective_period.min > date.end_of_month) ? benefit_application.effective_period.min : date.end_of_month
      s_benefits = benefit_application.benefit_packages.map(&:sponsored_benefits).flatten      
      enrollments = nil
      s_benefits.each do |sponsored_benefit|
        enrollments_by_month = HbxEnrollment.by_benefit_application_and_sponsored_benefit(
          benefit_application,
          sponsored_benefit,
          date
        )
        if enrollments.nil?
          enrollments = enrollments_by_month
        else
          enrollments = enrollments + enrollments_by_month
        end
      end
      enrollments
    end

    def query(sponsored_benefit, date)
      query = ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentsQuery.new(benefit_application, sponsored_benefit).call(::HbxEnrollment, date)
      return nil if query.count > 100
      query
    end

    def application_eligibility_warnings
      #fixed only attestation related bug #25241
      warnings = {}
      employer_profile = benefit_sponsorship.profile

      if employer_attestation_is_enabled?
        unless employer_profile.is_attestation_eligible?
          employer_attestation = employer_profile.employer_attestation
          if employer_attestation.blank? || employer_attestation.unsubmitted?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation not provided. Select <a href=/employers/employer_profiles/#{employer_profile.id}?tab=documents>Documents</a> on the blue menu to the left and follow the instructions to upload your documents."})
          elsif employer_attestation.denied?
            warnings.merge!({attestation_ineligible: "Employer attestation documentation was denied. This employer not eligible to enroll on the #{Settings.site.long_name}"})
          else
            warnings.merge!({attestation_ineligible: "Employer attestation error occurred: #{employer_attestation.aasm_state.humanize}. Please contact customer service."})
          end
        end
      end

      warnings
    end

    def today
      TimeKeeper.date_of_record
    end

    private

    def submit_application_warnings
      [application_errors.values + application_eligibility_warnings.values].flatten.reject(&:blank?)
    end
    
    def force_publish_warnings
      submit_warnings = []
      submit_warnings += business_policy.fail_results.values unless business_policy.fail_results.values.blank?
      submit_warnings += submit_application_warnings unless submit_application_warnings.blank?
      submit_warnings
    end

    def validate_benefit_application_termination_date(end_on, termination_kind)
      errors = {}
      result = true
      if termination_kind == 'voluntary'
        if !allow_mid_month_voluntary_terms? && end_on.to_date != end_on.end_of_month.to_date
          result = false
          errors[:mid_month_voluntary_term] = "Exchange doesn't allow mid month voluntary terminations"
        end
      elsif termination_kind == 'nonpayment'
        if !allow_mid_month_non_payment_terms? && end_on.to_date != end_on.end_of_month.to_date
          result = false
          errors[:mid_month_non_payment_term] = "Exchange doesn't allow mid month non payment terminations"
        end
      end
      [result, errors]
    end

    def business_policy_satisfied_for?(event_name)
      business_policy_name = policy_name(event_name)
      @business_policy = business_policy_for(business_policy_name)
      @business_policy.blank? || @business_policy.is_satisfied?(benefit_application)
    end

    def business_policy_for(business_policy_name)
      if business_policy_name == :end_open_enrollment
        enrollment_eligibility_policy_for(benefit_application, business_policy_name)
      else
        application_eligibility_policy_for(benefit_application, business_policy_name)
      end
    end

    def policy_name(event_name)
      event_name
    end

    def calculate_pricing_determinations(b_application)
      ::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator.call(b_application, today)
    end

    def log_message(errors)
      msg = yield.first
      (errors[msg[0]] ||= []) << msg[1]
    end

    def application_eligibility_policy_for(benefit_application, business_policy_name)
      BenefitSponsors::BusinessPolicies::PolicyResolver.benefit_application_eligibility_policy_for(benefit_application, business_policy_name)
    end

    def enrollment_eligibility_policy_for(benefit_application, event_name)
      BenefitSponsors::BusinessPolicies::PolicyResolver.benefit_application_enrollment_eligibility_policy_for(benefit_application, event_name)
    end

    def due_date_for_publish
      if benefit_sponsorship.benefit_applications.is_renewing.any?
        Date.new(benefit_application.start_on.prev_month.year, benefit_application.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month)
      else
        Date.new(benefit_application.start_on.prev_month.year, benefit_application.start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month)
      end
    end

    def application_errors
      {}
    end

    #TODO: FIX this
    def non_owner_employee_present?
      benefit_application.benefit_packages.any?{ |benefit_package|
        benefit_package.census_employees_assigned_on(benefit_application.start_on).active.non_business_owner.present?
      }
    end
  end
end
