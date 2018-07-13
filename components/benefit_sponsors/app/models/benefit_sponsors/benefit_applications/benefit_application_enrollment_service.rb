module BenefitSponsors
  class BenefitApplications::BenefitApplicationEnrollmentService
    include Config::AcaModelConcern

    attr_reader   :benefit_application, :business_policy


    def initialize(benefit_application)
      @benefit_application   = benefit_application
    end

    def renew_application
      if business_policy_satisfied_for?(:renew_benefit_application)
        renewal_effective_date = benefit_application.effective_period.end.to_date.next_day
        service_areas = benefit_application.benefit_sponsorship.service_areas_on(renewal_effective_date)
        benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(service_areas, renewal_effective_date)

        if benefit_sponsor_catalog
          new_benefit_application = benefit_application.renew(benefit_sponsor_catalog)
          if new_benefit_application.save
            benefit_sponsor_catalog.save
          end
        end

        [true, new_benefit_application, business_policy.success_results]
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

    def force_submit_application
      if is_application_valid? && is_application_eligible?
        if benefit_application.may_approve_application?
          benefit_application.auto_approve_application!
          if today >= benefit_application.open_enrollment_period.begin
            benefit_application.begin_open_enrollment!
          end
        end
      else
        benefit_application.submit_for_review! if benefit_application.may_submit_for_review?
        errors = application_errors.merge(open_enrollment_date_errors)
        [false, benefit_application, errors]
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
            benefit_application.errors.add(:base => "State transition failed")
            return false
          end
        end
      else
        [false, benefit_application, business_policy.fail_results]
      end
    end

    def end_open_enrollment
      if business_policy_satisfied_for?(:end_open_enrollment)
        if benefit_application.may_end_open_enrollment?
          benefit_application.end_open_enrollment!
          benefit_application.approve_enrollment_eligiblity! if benefit_application.is_renewing? && benefit_application.may_approve_enrollment_eligiblity?
          calculate_pricing_determinations(benefit_application)
          [true, benefit_application, business_policy.success_results]
        end
        [false, benefit_application, {:aasm_error => "may_end_open_enrollment? is false"}]
      else
        benefit_application.end_open_enrollment! if benefit_application.may_end_open_enrollment?
        benefit_application.deny_enrollment_eligiblity! if benefit_application.may_deny_enrollment_eligiblity?
        [false, benefit_application, business_policy.fail_results]
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

    def cancel
      if business_policy_satisfied_for?(:cancel_benefit)
        if benefit_application.may_cancel?
          benefit_application.cancel!
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

    def terminate(end_on, termination_date)
      if business_policy_satisfied_for?(:terminate_benefit)
        if benefit_application.may_terminate_enrollment?
          benefit_application.terminate_enrollment!
          if benefit_application.terminated?
            updated_dates = benefit_application.effective_period.min.to_date..end_on
            benefit_application.update_attributes!(:effective_period => updated_dates, :terminated_on => termination_date)
          end
        end
      else
        [false, benefit_application, business_policy.fail_results]
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
    def extend_open_enrollment(benefit_application, new_end_date)

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
      enrollment_proxies = BenefitApplications::BenefitApplicationEnrollmentsQuery.new(benefit_application).call(Family, date)
      return [] if (enrollment_proxies.count > 100)
      enrollment_proxies.map do |ep|
        OpenStruct.new(ep)
      end
    end

    def hbx_enrollments_by_month(date)
      s_benefits = benefit_application.benefit_packages.map(&:sponsored_benefits).flatten
      collection = s_benefits.map { |s_benefit| [s_benefit, query(s_benefit, date)] }
      enrollments = collection[0].last.map do |col|
        col["hbx_enrollments"]
      end
      enrollments
    end

    def query(sponsored_benefit, date)
      query = ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentsQuery.new(benefit_application, sponsored_benefit).call(::Family, date)
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

    def business_policy_satisfied_for?(event_name)
      business_policy_name = policy_name(event_name)
      @business_policy = business_policy_for(business_policy_name)
      @business_policy.blank? || @business_policy.is_satisfied?(benefit_application)
    end

    def business_policy_for(business_policy_name)
      if business_policy_name == :end_open_enrollment
        enrollment_eligibility_policy.business_policies_for(benefit_application, business_policy_name)
      else
        application_eligibility_policy.business_policies_for(benefit_application, business_policy_name)
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

    def application_eligibility_policy
      return @application_eligibility_policy if defined?(@application_eligibility_policy)
      @application_eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
    end

    def enrollment_eligibility_policy
      return @enrollment_eligibility_policy if defined?(@enrollment_eligibility_policy)
      @enrollment_eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
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
