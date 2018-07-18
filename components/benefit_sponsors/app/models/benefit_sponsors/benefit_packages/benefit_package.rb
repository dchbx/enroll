module BenefitSponsors
  module BenefitPackages
    class BenefitPackage
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :benefit_application, class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication",
                  inverse_of: :benefit_packages

      field :title, type: String, default: ""
      field :description, type: String, default: ""
      field :probation_period_kind, type: Symbol
      field :is_default, type: Boolean, default: false
      field :is_active, type: Boolean, default: true
      field :predecessor_id, type: BSON::ObjectId

      # Deprecated: replaced by FEHB profile and FEHB market
      # field :is_congress, type: Boolean, default: false

      embeds_many :sponsored_benefits,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit",
                  cascade_callbacks: true, validate: true

      accepts_nested_attributes_for :sponsored_benefits

      delegate :benefit_sponsor_catalog, to: :benefit_application
      delegate :rate_schedule_date,      to: :benefit_application
      delegate :effective_period,        to: :benefit_application
      delegate :recorded_sic_code, to: :benefit_application

      delegate :start_on, :end_on, :open_enrollment_period, to: :benefit_application
      delegate :open_enrollment_start_on, :open_enrollment_end_on, to: :benefit_application
      delegate :recorded_rating_area, to: :benefit_application
      delegate :benefit_sponsorship, :sponsor_profile, to: :benefit_application
      delegate :recorded_service_area_ids, to: :benefit_application
      delegate :benefit_market, to: :benefit_application
      delegate :is_conversion?, to: :benefit_application

      validates_presence_of :title, :probation_period_kind, :is_default, :is_active #, :sponsored_benefits

      default_scope ->{ where(is_active: true) }

      # calculate effective on date based on probation period kind
      # Logic to deal with hired_on and created_at
      # returns a roster
      def new_hire_effective_on(roster)
      end

      def eligible_on(date_of_hire) # date_of_hire probation type is deprecated
        return (date_of_hire + effective_on_offset.days) if (date_of_hire + effective_on_offset.days).day == 1

        (date_of_hire + effective_on_offset.days).end_of_month + 1.day
      end

      def effective_on_for(date_of_hire)
        [start_on, eligible_on(date_of_hire)].max
      end

      def effective_on_for_cobra(date_of_hire)
        [start_on, eligible_on(date_of_hire)].max
      end

      def open_enrollment_contains?(date)
        open_enrollment_period.include?(date)
      end

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

      def successor
        self.benefit_application.benefit_sponsorship.benefit_applications.flat_map(&:benefit_packages).detect do |bp|
          bp.predecessor_id.to_s == self.id.to_s
        end
      end

      def package_for_date(coverage_start_date)
        if (coverage_start_date <= end_on) && (coverage_start_date >= start_on)
          return self
        elsif (coverage_start_date < start_on)
          return nil unless predecessor.present?
          predecessor.package_for_date(coverage_start_date)
        else
          return nil unless successor.present?
          successor.package_for_date(coverage_start_date)
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
          first_of_month_after_30_days: 'first_of_month',
          first_of_month_after_60_days: 'first_of_month'

        }

        effective_on_kind_mapping[probation_period_kind]
      end

      def effective_on_offset
        offset_mapping = {
          first_of_month: 0,
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
          first_of_month: "First of the month following or coinciding with date of hire",
          first_of_month_after_30_days: "First of the month following 30 days",
          first_of_month_after_60_days: "First of the month following 60 days"
        }

        probation_period_display_texts[probation_period_kind]
      end

      def activate_benefit_group_assignments
        CensusEmployee.by_benefit_package_and_assignment_on(self, start_on, false).non_terminated.each do |ce|
          ce.benefit_group_assignments.each do |bga|
            if bga.benefit_package_id == self.id
              bga.make_active
            end
          end
        end
      end

      def renew(new_benefit_package)
        new_benefit_package.assign_attributes({
          title: title + "(#{start_on.year + 1})",
          description: description,
          probation_period_kind: probation_period_kind,
          is_default: is_default
        })

        new_benefit_package.predecessor = self

        sponsored_benefits.each do |sponsored_benefit|
          new_benefit_package.add_sponsored_benefit(sponsored_benefit.renew(new_benefit_package))
        end
        new_benefit_package
      end

      def renew_employee_assignments
        assigned_census_employees = predecessor.census_employees_assigned_on(predecessor.start_on)

        assigned_census_employees.each do |census_employee|
          new_benefit_package_assignment = census_employee.benefit_package_assignment_on(start_on)

          if new_benefit_package_assignment.blank?
            census_employee.assign_to_benefit_package(self, effective_period.min)
          end
        end
      end

      def renew_member_benefits
        # FIXME: There is no reason to assume that the renewal benefit package assignment
        #        will have is_active == false, I think this may always return an empty set.
        #        Because of this, I have removed the 'false' constraint.
        census_employees_assigned_on(effective_period.min).each { |member| renew_member_benefit(member) }
      end

      def renew_member_benefit(census_employee)
        predecessor_benefit_package = predecessor

        employee_role = census_employee.employee_role
        return [false, "no employee_role"] unless employee_role
        family = employee_role.primary_family

        return [false, "family missing for #{census_employee.full_name}"] if family.blank?

        # family.validate_member_eligibility_policy
        if true #family.is_valid?
          enrollments = family.enrollments.by_benefit_sponsorship(benefit_sponsorship)
          .by_effective_period(predecessor_benefit_package.effective_period)
          .enrolled_and_waived

          sponsored_benefits.map(&:product_kind).each do |product_kind|
            hbx_enrollment = enrollments.by_coverage_kind(product_kind).first

            if hbx_enrollment && is_renewal_benefit_available?(hbx_enrollment)
              hbx_enrollment.renew_benefit(self)
            end
          end
        end
      end

      def is_renewal_benefit_available?(enrollment)
        return false if enrollment.blank? || enrollment.product.blank? || enrollment.product.renewal_product.blank?
        sponsored_benefit = sponsored_benefit_for(enrollment.coverage_kind)
        sponsored_benefit.product_package.products.include?(enrollment.product.renewal_product)
      end

      def enrolled_families
        Family.enrolled_through_benefit_package(self)
      end

      def effectuate_member_benefits
        enrolled_families.each do |family| 
          enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first
            hbx_enrollment.begin_coverage! if hbx_enrollment && hbx_enrollment.may_begin_coverage?
          end
        end
      end

      def expire_member_benefits
        enrolled_families.each do |family|
          enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first
            hbx_enrollment.expire_coverage! if hbx_enrollment && hbx_enrollment.may_expire_coverage?
          end
        end
      end
 
      def terminate_member_benefits
        enrolled_families.each do |family|
          enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first
            
            if hbx_enrollment && hbx_enrollment.may_terminate_coverage?
              hbx_enrollment.terminate_coverage!
              hbx_enrollment.update_attributes!(terminated_on: benefit_application.end_on, termination_submitted_on: benefit_application.terminated_on)
            end
          end
        end
      end

      def cancel_member_benefits(delete_benefit_package: false)
        deactivate_benefit_group_assignments
        enrolled_families.each do |family|
          enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived

          sponsored_benefits.each do |sponsored_benefit|
            hbx_enrollment = enrollments.by_coverage_kind(sponsored_benefit.product_kind).first
            hbx_enrollment.cancel_coverage! if hbx_enrollment && hbx_enrollment.may_cancel_coverage?
          end
        end
        deactivate if delete_benefit_package
      end

      def deactivate_benefit_group_assignments
        self.benefit_application.benefit_sponsorship.census_employees.each do |ce|
          benefit_group_assignments = ce.benefit_group_assignments.where(benefit_group_id: self.id)
          benefit_group_assignments.each do |benefit_group_assignment|
            benefit_group_assignment.update(is_active: false) unless self.benefit_application.is_renewing?
          end

          other_benefit_package = self.benefit_application.benefit_packages.detect{ |bp| bp.id != self.id}
          if other_benefit_package.present?
            if self.benefit_application.is_renewing?
              ce.add_renew_benefit_group_assignment([other_benefit_package])
            else
              ce.find_or_create_benefit_group_assignment([other_benefit_package])
            end
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

      def census_employees_assigned_on(effective_date, is_active = true)
        CensusEmployee.by_benefit_package_and_assignment_on(self, effective_date, is_active).non_terminated
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
