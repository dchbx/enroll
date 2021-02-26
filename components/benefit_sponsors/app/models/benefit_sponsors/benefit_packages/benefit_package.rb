module BenefitSponsors
  module BenefitPackages
    class BenefitPackage
      include Mongoid::Document
      include Mongoid::Timestamps
      include Acapi::Notifiers


      embedded_in :benefit_application,
                  class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication",
                  inverse_of: :benefit_packages

      field :title, type: String, default: ""
      field :description, type: String, default: ""
      field :probation_period_kind, type: Symbol
      field :is_default, type: Boolean, default: false
      field :is_active, type: Boolean, default: true
      field :predecessor_id, type: BSON::ObjectId  # Deprecated

      # Deprecated: replaced by FEHB profile and FEHB market
      # field :is_congress, type: Boolean, default: false

      embeds_many :sponsored_benefits,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit",
                  inverse_of: :benefit_package,
                  cascade_callbacks: true, validate: true

      accepts_nested_attributes_for :sponsored_benefits

      delegate :benefit_sponsor_catalog, to: :benefit_application
      delegate :rate_schedule_date,      to: :benefit_application
      delegate :effective_period,        to: :benefit_application
      delegate :recorded_sic_code,       to: :benefit_application

      delegate :start_on, :end_on, :open_enrollment_period, to: :benefit_application
      delegate :open_enrollment_start_on, :open_enrollment_end_on, to: :benefit_application
      delegate :recorded_rating_area, to: :benefit_application
      delegate :benefit_sponsorship, :sponsor_profile, to: :benefit_application
      delegate :recorded_service_area_ids, to: :benefit_application
      delegate :benefit_market, to: :benefit_application
      delegate :is_conversion?, to: :benefit_application
      delegate :is_renewing?,   to: :benefit_application
      delegate :shoppable?,     to: :benefit_application
      delegate :cover?,         to: :effective_period

      validates_presence_of :title, :probation_period_kind, :is_default, :is_active #, :sponsored_benefits

      default_scope ->{ where(is_active: true) }

      # calculate effective on date based on probation period kind
      # Logic to deal with hired_on and created_at
      # returns a roster
      def new_hire_effective_on(roster)
      end

      def eligible_on(date_of_hire) # date_of_hire probation type is deprecated
        if effective_on_offset == 1
          date_of_hire.end_of_month + 1.day
        else
          return (date_of_hire + effective_on_offset.days) if (date_of_hire + effective_on_offset.days).day == 1

          (date_of_hire + effective_on_offset.days).end_of_month + 1.day
        end
      end

      def effective_on_for(date_of_hire)
        [start_on.to_date, eligible_on(date_of_hire)].max
      end

      def effective_on_for_cobra(date_of_hire)
        [start_on, eligible_on(date_of_hire)].max
      end

      def open_enrollment_contains?(date)
        open_enrollment_period.include?(date)
      end

      # def cover?(date)
      #   effective_period.cover?(date)
      # end



      def package_for_open_enrollment(shopping_date)
        if open_enrollment_period.include?(shopping_date)
          return self
        elsif (shopping_date < open_enrollment_start_on)
          return nil unless predecessor.present?
          predecessor.package_for_open_enrollment(shopping_date)
        else
          return nil unless successor.present?
          successor.package_for_open_enrollment(shopping_date)
        end
      end

      def predecessor_application
        return nil unless benefit_application
        benefit_application.predecessor
      end

      # deprecated. Do not use. Use successor_benefit_package on benefit application instead.
      def successor
        self.benefit_application.benefit_sponsorship.benefit_applications.flat_map(&:benefit_packages).detect do |bp|
          bp.predecessor_id.to_s == self.id.to_s && (bp.benefit_application.is_submitted?)
        end
      end


      # TODO: there can be only one sponsored benefit of each kind
      def add_sponsored_benefit(new_sponsored_benefit)
        new_sponsored_benefit
      end

      def effective_on_kind
        effective_on_kind_mapping = {
          date_of_hire: 'date_of_hire',
          first_of_month: 'first_of_month',
          first_of_month_following: 'first_of_month',
          first_of_month_after_30_days: 'first_of_month',
          first_of_month_after_60_days: 'first_of_month'
        }

        effective_on_kind_mapping[probation_period_kind]
      end

      def effective_on_offset
        offset_mapping = {
          date_of_hire: 0,
          first_of_month: 0,
          first_of_month_following: 1,
          first_of_month_after_30_days: 30,
          first_of_month_after_60_days: 60
        }

        offset_mapping[probation_period_kind]
      end

      def sorted_composite_tier_contributions
        health_sponsored_benefit.sponsor_contribution.contribution_levels
      end

      def sole_source?
        if health_sponsored_benefit
          health_sponsored_benefit.product_package_kind == :single_product
        else
          false
        end
      end

      def plan_option_kind
        if health_sponsored_benefit
          health_sponsored_benefit.product_package_kind.to_s
        end
      end

      def reference_plan
        if health_sponsored_benefit
          health_sponsored_benefit.reference_product
        end
      end

      def dental_reference_plan
        if dental_sponsored_benefit
          dental_sponsored_benefit.reference_product
        end
      end

      def health_sponsored_benefit
        sponsored_benefits.where(_type: /.*HealthSponsoredBenefit/).first
      end

      def dental_sponsored_benefit
        sponsored_benefits.where(_type: /.*DentalSponsoredBenefit/).first
      end

      def rating_area
        recorded_rating_area.blank? ? benefit_group.benefit_sponsorship.rating_area : recorded_rating_area
      end

      def drop_sponsored_benefit(sponsored_benefit)
        sponsored_benefits.delete(sponsored_benefit)
      end

      # deprecated. Do not use. Use predecessor_benefit_package on benefit application instead.
      def predecessor
        return nil if predecessor_id.blank?
        return @predecessor if @predecessor
        @predecessor = predecessor_application.benefit_packages.find(self.predecessor_id)
      end

      def predecessor=(old_benefit_package)
        raise ArgumentError.new("expected BenefitPackage") unless old_benefit_package.kind_of? BenefitSponsors::BenefitPackages::BenefitPackage
        @predecessor = old_benefit_package
        self.predecessor_id = old_benefit_package.id
      end

      def probation_period_display_name
        probation_period_display_texts = {
          date_of_hire: "Date of hire",
          first_of_month: "First of the month following or coinciding with date of hire",
          first_of_month_following: "First of the month following date of hire",
          first_of_month_after_30_days: "First of the month following 30 days",
          first_of_month_after_60_days: "First of the month following 60 days"
        }

        probation_period_display_texts[probation_period_kind]
      end

      def renew(new_benefit_package)
        new_benefit_package.assign_attributes({
          title: title + "(#{start_on.year + 1})",
          description: description,
          probation_period_kind: probation_period_kind,
          is_default: is_default
        })

        new_benefit_package.predecessor = self

        sponsored_benefits.unscoped.each do |sponsored_benefit|
          new_benefit_package.add_sponsored_benefit(sponsored_benefit.renew(new_benefit_package))
        end
        new_benefit_package
      end

      def renew_employee_assignment(census_employee, package_effective_date)
        new_benefit_package_assignment = census_employee.benefit_package_assignment_on(package_effective_date)

        if new_benefit_package_assignment.blank?
          census_employee.assign_to_benefit_package(self, package_effective_date)
        end
      end

      def renew_employee_assignments(predecessor_benefit_package, async_workflow_id = nil)
        return unless predecessor_benefit_package

        assigned_census_employees = predecessor_benefit_package.eligible_assigned_census_employees(predecessor_benefit_package.start_on)

        assigned_census_employees.each do |census_employee|
          if async_workflow_id.blank?
            renew_employee_assignment(census_employee, start_on)
          else
            notify(
              "acapi.info.events.benefit_package.renew_employee_assignment",
              {
                :workflow_id => async_workflow_id.to_s,
                :benefit_package_id => id.to_s,
                :census_employee_id => census_employee.id.to_s,
                :effective_on_date => start_on.strftime("%Y-%m-%d")
              }
            )
          end
        end
      end

      def renew_member_benefits
        # FIXME: There is no reason to assume that the renewal benefit package assignment
        #        will have is_active == false, I think this may always return an empty set.
        #        Because of this, I have removed the 'false' constraint.

        # FIXME: Currently to avoid breaking tests I am using the old behaviour
        #        as I am not sure what tests rely on renewal.
        #        Correct and updates specs IMMEDIATELY.

        census_employees_assigned_on(effective_period.min).each do |member|
          if Rails.env.test?
            renew_member_benefit(member)
          else
            trigger_renew_employee_event(member)
          end
        end
      end

      def trigger_renew_employee_event(census_employee)
        notify(
          "acapi.info.events.benefit_package.renew_employee",
          {
            :census_employee_id => census_employee.id.to_s,
            :benefit_package_id => self.id.to_s
          }
        )
      end

      # FIXME: Nowhere do we check the result of this method.
      #        Notice also how it only returns a known result of the form
      #        [boolean, message] when failure happens.  What is it
      #        supposed to return when things go correctly?
      def renew_member_benefit(census_employee, result_reporter = SilentRenewalReporter.new)
        employee_role = census_employee.employee_role
        result_reporter.report_renewal_failure(census_employee, self, "no employee_role") unless employee_role
        return [false, "no employee_role"] unless employee_role
        family = employee_role.primary_family
        result_reporter.report_renewal_failure(census_employee, self, "family missing for #{census_employee.full_name}") if family.blank?
        return [false, "family missing for #{census_employee.full_name}"] if family.blank?

        # family.validate_member_eligibility_policy
        if true #family.is_valid?
          enrollments = family.active_household.hbx_enrollments.enrolled_and_waived
          .by_benefit_sponsorship(benefit_sponsorship).by_effective_period(predecessor_application.effective_period)

          renewing_enrollments = family.active_household.hbx_enrollments.enrolled_waived_and_renewing
                                       .by_benefit_sponsorship(benefit_sponsorship).by_effective_period(effective_period)

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first

            renewing_enrollment = renewing_enrollments.by_coverage_kind(sponsored_benefit.product_kind).first

            next if renewing_enrollment.present?

            if hbx_enrollment && is_renewal_benefit_available?(hbx_enrollment)
              renewed_enrollment = hbx_enrollment.renew_benefit(self, result_reporter)
            end

            trigger_renewal_model_event(sponsored_benefit, census_employee, renewed_enrollment)
          end
        end
      end

      def trigger_renewal_model_event(sponsored_benefit, census_employee, renewed_enrollment = nil)
        return unless sponsored_benefit.health?

        renewal_model_event = if renewed_enrollment.present?
          renewed_enrollment.is_coverage_waived? ? :employee_coverage_passively_waived : :employee_coverage_passively_renewed
        else
          :employee_coverage_passive_renewal_failed
        end

        census_employee.trigger_model_event(renewal_model_event, {event_object: self.benefit_application})
      end

      def is_renewal_benefit_available?(enrollment)
        return true if (enrollment.present? && enrollment.is_coverage_waived?)
        return false if enrollment.present? && enrollment.coverage_termination_pending?
        return false if enrollment.blank? || enrollment.product.blank? || enrollment.product.renewal_product.blank?
        sponsored_benefit = sponsored_benefit_for(enrollment.coverage_kind)
        sponsored_benefit.products(start_on).include?(enrollment.product.renewal_product)
      end

      def enrolled_families
        ::Family.enrolled_through_benefit_package(self)
      end

      def enrolled_and_terminated_families
        ::Family.enrolled_and_terminated_through_benefit_package(self)
      end

      def effectuate_member_benefits
        logger = Logger.new("#{Rails.root}/log/benefit_package_effectuate_member_benefits.log")
        activate_benefit_group_assignments if predecessor_application.present?

        enrolled_families.no_timeout.inject([]) do |_dummy, family|
          enrollments = HbxEnrollment.by_benefit_package(self).where(family_id: family.id).show_enrollments_sans_canceled

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first
            hbx_enrollment.begin_coverage!({skip_renewal_coverage_update: true}) if hbx_enrollment&.may_begin_coverage?
          rescue StandardError => e
            logger.info "error raised for family: #{family.id}, error: #{e.backtrace}"
          end
        end
      end

      def expire_member_benefits
        enrolled_families.no_timeout.each do |family|
          enrollments = HbxEnrollment.by_benefit_package(self).where(family_id: family.id).enrolled_and_waived

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first
            hbx_enrollment.expire_coverage! if hbx_enrollment && hbx_enrollment.may_expire_coverage?
          end
        end
      end

      def terminate_member_benefits(term_date: nil, enroll_term_reason: nil, enroll_notify: false)
        terminate_benefit_group_assignments
        enrolled_and_terminated_families.each do |family|
          enrollments = family.hbx_enrollments.enrolled_waived_terminated_and_expired.by_benefit_package(self)
          enrollments.each do |hbx_enrollment|
            if hbx_enrollment.effective_on > enrollment_term_date(term_date)
              if hbx_enrollment.may_cancel_coverage?
                hbx_enrollment.cancel_coverage!(enrollment_term_date(term_date))
                hbx_enrollment.notify_enrollment_cancel_or_termination_event(enrollment_notify_flag(enroll_notify))
              end
            elsif hbx_enrollment.coverage_termination_pending? && hbx_enrollment.terminated_on.present? && (hbx_enrollment.terminated_on < enrollment_term_date(term_date))
              # do nothing
            elsif hbx_enrollment.may_terminate_coverage?
              if hbx_enrollment.terminated_on.nil? || (hbx_enrollment.terminated_on.present? && (hbx_enrollment.terminated_on > enrollment_term_date(term_date)))
                hbx_enrollment.update_attributes!(terminated_on: enrollment_term_date(term_date), terminate_reason: enrollment_term_reason(enroll_term_reason), termination_submitted_on: enrollment_term_submitted)
                hbx_enrollment.terminate_coverage!(enrollment_term_date(term_date))
                hbx_enrollment.notify_enrollment_cancel_or_termination_event(enrollment_notify_flag(enroll_notify))
              end
            end
          end
        end
      end

      def termination_pending_member_benefits(term_date: nil, enroll_term_reason: nil, enroll_notify: false)
        terminate_benefit_group_assignments
        enrolled_families.no_timeout.each do |family|
          enrollments = family.hbx_enrollments.enrolled_waived_terminated_and_expired.by_benefit_package(self)
          enrollments.each do |hbx_enrollment|
            if hbx_enrollment.effective_on > enrollment_term_date(term_date)
              if hbx_enrollment.may_cancel_coverage?
                hbx_enrollment.cancel_coverage!(enrollment_term_date(term_date))
                hbx_enrollment.notify_enrollment_cancel_or_termination_event(enrollment_notify_flag(enroll_notify))
              end
            elsif hbx_enrollment.coverage_termination_pending? && hbx_enrollment.terminated_on.present? && (hbx_enrollment.terminated_on < enrollment_term_date(term_date))
              # do nothing
            elsif hbx_enrollment.may_schedule_coverage_termination?
              hbx_enrollment.update_attributes!(terminated_on: enrollment_term_date(term_date), terminate_reason: enrollment_term_reason(enroll_term_reason), termination_submitted_on: enrollment_term_submitted)
              hbx_enrollment.schedule_coverage_termination!(enrollment_term_date(term_date))
              hbx_enrollment.notify_enrollment_cancel_or_termination_event(enrollment_notify_flag(enroll_notify))
            end
          end
        end
      end

      def cancel_member_benefits(delete_benefit_package: false, enroll_notify: false)
        deactivate_benefit_group_assignments

        enrolled_families.no_timeout.each do |family|
          enrollments = HbxEnrollment.by_benefit_package(self).where(family_id: family.id).show_enrollments_sans_canceled
          enrollments.each do |hbx_enrollment|
            if hbx_enrollment.may_cancel_coverage?
              hbx_enrollment.cancel_coverage!
              hbx_enrollment.notify_enrollment_cancel_or_termination_event(enrollment_notify_flag(enroll_notify)) unless hbx_enrollment.inactive?
            end
          end
        end

        if delete_benefit_package
          other_benefit_package = self.benefit_application.benefit_packages.detect{ |bp| bp.id != self.id}
          assign_other_benefit_package(other_benefit_package) if other_benefit_package.present?
          deactivate
        end
      end

      def canceled_as_ineligible?(transition)
        transition.from_state == 'enrollment_ineligible' && transition.to_state == 'canceled'
      end

      def enrollment_term_reason(term_reason)
        return term_reason if term_reason
        benefit_application.termination_kind == "nonpayment" ? "non_payment" : "voluntary_withdrawl" if benefit_application.termination_kind
      end

      def enrollment_term_date(term_date)
        return term_date if term_date
        benefit_application.end_on
      end

      def enrollment_term_submitted
        benefit_application.terminated_on || TimeKeeper.date_of_record
      end

      def enrollment_notify_flag(notify_enroll)
        return notify_enroll if notify_enroll
        benefit_application.is_application_trading_partner_publishable? ? true : false
      end

      def canceled_after?(transition, cancellation_time)
        transition.to_state == 'coverage_canceled' && transition.transition_at >= cancellation_time
      end

      def reinstate_canceled_member_benefits
        activate_benefit_group_assignments unless benefit_application.is_renewing?
        application_transition = benefit_application.workflow_state_transitions.detect{|transition| canceled_as_ineligible?(transition) }
        return if application_transition.blank?

        Family.all_enrollments_by_benefit_package(self).each do |family|
          enrollments = family.active_household.hbx_enrollments.by_benefit_package(self)
          canceled_coverages = enrollments.canceled.select{|enrollment| enrollment.workflow_state_transitions.any?{|wst| canceled_after?(wst, application_transition.transition_at) } }
          if canceled_coverages.present?
            sponsored_benefits.each do |sponsored_benefit|
              hbx_enrollment = canceled_coverages.detect{|coverage| coverage.coverage_kind == sponsored_benefit.product_kind.to_s}
              enrollment_transition = hbx_enrollment.workflow_state_transitions[0] if hbx_enrollment.present?

              if enrollment_transition.present? && enrollment_transition.to_state == hbx_enrollment.aasm_state
                hbx_enrollment.update(aasm_state: enrollment_transition.from_state)
                hbx_enrollment.workflow_state_transitions.create(from_state: enrollment_transition.to_state, to_state: enrollment_transition.from_state)

                hbx_enrollment.benefit_group_assignment.update_status_from_enrollment(hbx_enrollment)
              end
            end
          end
        end
      end

      def eligible_assigned_census_employees(effective_date)
        CensusEmployee.by_benefit_package_and_assignment_on_or_later(self, effective_date).non_term_and_pending
      end

      def assign_other_benefit_package(other_benefit_package)
        self.benefit_application.benefit_sponsorship.census_employees.each do |ce|
          if is_renewing?
            ce.add_renew_benefit_group_assignment([other_benefit_package])
          else
            ce.create_benefit_group_assignment([other_benefit_package])
          end
        end
      end

      def activate_benefit_group_assignments
        CensusEmployee.by_benefit_package_and_assignment_on(self, start_on).non_terminated.no_timeout.inject([]) do |_dummy, ce|
          ce.benefit_group_assignments.where(benefit_package_id: self.id).last&.make_active
        end
      end

      # TODO: Figure this out and depracate
      def deactivate_benefit_group_assignments
        self.benefit_application.benefit_sponsorship.census_employees.each do |ce|
          benefit_group_assignments = ce.benefit_group_assignments.where(benefit_package_id: self.id)
          benefit_group_assignments.each do |benefit_group_assignment|
            benefit_group_assignment.update(end_on: benefit_group_assignment.start_on) unless is_renewing?
          end
        end
      end

      def terminate_benefit_group_assignments
        benefit_application.benefit_sponsorship.census_employees.each do |ce|
          benefit_group_assignments = ce.benefit_group_assignments.where(benefit_package_id: id)
          benefit_group_assignments.each do |benefit_group_assignment|
            benefit_group_assignment.update(end_on: end_on) if benefit_group_assignment&.end_on != end_on
          end
        end
      end

      def deactivate
        self.update_attributes(is_active: false)
      end

      def issuers_offered_for(product_kind)
        sponsored_benefit = sponsored_benefit_for(product_kind)
        return [] unless sponsored_benefit
        sponsored_benefit.issuers_offered
      end

      def sponsored_benefit_for(coverage_kind)
        sponsored_benefits.detect{|sponsored_benefit| sponsored_benefit.product_kind == coverage_kind.to_sym }
      end

      def is_offering_dental?
        sponsored_benefit_for(:dental).present?
      end

      def census_employees_assigned_on(effective_date)
        CensusEmployee.by_benefit_package_and_assignment_on(self, effective_date).non_term_and_pending
      end

      def census_employees_eligible_for_renewal(effective_date)
        CensusEmployee.eligible_for_renewal_under_package(self, start_on, end_on, effective_date)
      end

      def self.find(id)
        ::Caches::RequestScopedCache.lookup(:employer_calculation_cache_for_benefit_groups, id) do
          benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_package_find(id).first
          benefit_sponsorship.benefit_package_by(id)
        end
      end

      # Scenario 1: sponsored_benefit is missing (because product not available during renewal)
      def refresh

      end

      #  Scenario 2: sponsored_benefit is present
      def refresh!(new_benefit_sponsor_catalog)
        # construct sponsored benefits again
        # compare them with old ones

        sponsored_benefits.each do |sponsored_benefit|
          current_product_package = sponsored_benefit.product_package
          new_product_package = new_benefit_sponsor_catalog.product_package_for(sponsored_benefit)

          if current_product_package != new_product_package
            sponsored_benefit.refresh
          end
        end
      end

      def build_relationship_benefits
      end

      def build_dental_relationship_benefits
      end

      def self.transform_to_sponsored_benefit_template(product_package)
        sponsored_benefit = TransformProductPackageToSponsoredBenefit.new(product_package).transform
      end

      def set_sponsor_choices(sponsored_benefit)
        # trigger composite

      end

      def sponsored_benefits=(sponsored_benefits_attrs)
        sponsored_benefits_attrs.each do |sponsored_benefit_attrs|
          sponsored_benefit = sponsored_benefits.build
          sponsored_benefit.assign_attributes(sponsored_benefit_attrs)
        end
      end

      # Deprecate below methods in future

      def plan_year
        warn "[Deprecated] Instead use benefit_application" unless Rails.env.test?
        benefit_application
      end
    end
  end
end
