module BenefitSponsors
  module SponsoredBenefits
    class CensusEmployeeCoverageCostEstimator
      EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled) do
        def is_disabled?
          is_disabled
        end

        def is_primary_member?
          is_primary_member
        end
      end

      class CensusEmployeeMemberGroupMapper
        include Enumerable

        attr_reader :reference_product
        attr_reader :coverage_start, :census_employees

        def initialize(census_employees, r_product, c_start, s_benefit)
          @reference_product = r_product
          @coverage_start = c_start
          @census_employees = census_employees
          @sponsored_benefit = s_benefit
        end

        def each
          census_employees.each do |ce|
            yield rosterize_census_employee(ce)
          end
        end

        def map_ce_relationship(rel)
          {
            "spouse" => "spouse",
            "domestic_partner" => "domestic partner",
            "child_under_26" => "child",
            "disabled_child_26_and_over" => "disabled child"
          }[rel]
        end

        def map_ce_disabled(rel)
          rel == "disabled_child_26_and_over"
        end

        def rosterize_census_employee(census_employee)
          member_entries = [EnrollmentMemberAdapter.new(
            census_employee.id,
            census_employee.dob,
            "self",
            true,
            false
          )]
          member_enrollments = [::BenefitSponsors::Enrollments::MemberEnrollment.new({
            member_id: census_employee.id
          })]
          census_employee.census_dependents.each do |cm|
            if cm.dob <= coverage_start
              member_entries << EnrollmentMemberAdapter.new(
                cm.id,
                cm.dob,
                map_ce_relationship(cm.employee_relationship),
                false,
                map_ce_disabled(cm.employee_relationship)
              )
              member_enrollments << ::BenefitSponsors::Enrollments::MemberEnrollment.new({
                member_id: cm.id
              })
            end
          end
          group_enrollment = ::BenefitSponsors::Enrollments::GroupEnrollment.new(
            {
              product: reference_product,
              rate_schedule_date: @sponsored_benefit.rate_schedule_date,
              coverage_start_on: coverage_start,
              member_enrollments: member_enrollments,
              rating_area: @sponsored_benefit.recorded_rating_area.exchange_provided_code,
              sponsor_contribution_prohibited: ["cobra_eligible", "cobra_linked", "cobra_termination_pending"].include?(census_employee.aasm_state)
            })
          ::BenefitSponsors::Members::MemberGroup.new(
            member_entries,
            {group_enrollment: group_enrollment}
          )
        end
      end

      attr_reader :benefit_sponsorship, :coverage_start

      def initialize(b_sponsorship, c_start)
        @benefit_sponsorship = b_sponsorship
        @coverage_start = c_start
      end

      def calculate(sponsored_benefit, reference_product, p_package, rebuild_sponsor_contribution: false, build_new_pricing_determination: false)
        pricing_model = p_package.pricing_model
        contribution_model = p_package.contribution_model
        p_calculator = pricing_model.pricing_calculator
        c_calculator = contribution_model.contribution_calculator
        p_determination_builder = p_calculator.pricing_determination_builder
        sponsor_contribution = construct_sponsor_contribution_if_needed(sponsored_benefit, p_package, rebuild_sponsor_contribution)
        roster_eligibility_optimizer = RosterEligibilityOptimizer.new(contribution_model)
        price = 0.00
        contribution = 0.00
        if employees_enrolling.count < 1
          if p_determination_builder && build_new_pricing_determination
            create_fake_pricing_determination(sponsored_benefit, sponsor_contribution, pricing_model, contribution_model, p_determination_builder)
            return [sponsor_contribution, price, contribution]
          elsif p_determination_builder
            return [sponsor_contribution, price, contribution]
          else
            sponsored_benefit.pricing_determinations = []
          end
        end
        if p_determination_builder && build_new_pricing_determination
          precalculate_costs(
            sponsored_benefit,
            pricing_model,
            contribution_model,
            reference_product,
            sponsor_contribution,
            p_calculator,
            c_calculator,
            roster_eligibility_optimizer,
            p_determination_builder
          )
        elsif !p_determination_builder
          sponsored_benefit.pricing_determinations = []
        end
        price, contribution = calculate_normal_costs(
          pricing_model,
          contribution_model,
          reference_product,
          sponsor_contribution,
          p_calculator,
          c_calculator,
          roster_eligibility_optimizer,
          sponsored_benefit
        )
        [sponsor_contribution, price, contribution]
      end

      protected

      def construct_sponsor_contribution_if_needed(sponsored_benefit, product_package, rebuild_sponsor_contribution)
        if sponsored_benefit.sponsor_contribution.present?
          if rebuild_sponsor_contribution
            sponsored_benefit.sponsor_contribution = nil
          else
            return sponsored_benefit.sponsor_contribution
          end
        end
        cm_builder = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
        sponsor_contribution = cm_builder.build_sponsor_contribution(product_package)
        sponsor_contribution.sponsored_benefit = sponsored_benefit
        sponsor_contribution
      end

      def create_fake_pricing_determination(sponsored_benefit, sponsor_contribution, pricing_model, contribution_model, p_determination_builder_klass)
        p_determination_builder = p_determination_builder_klass.new
        p_determination_builder.create_fake_pricing_determinations(sponsored_benefit, pricing_model)
      end

      def precalculate_costs(
        sponsored_benefit,
        pricing_model,
        contribution_model,
        reference_product,
        sponsor_contribution,
        p_calculator,
        c_calculator,
        roster_eligibility_optimizer,
        p_determination_builder_klass
      )
        p_determination_builder = p_determination_builder_klass.new
        group_size = calculate_group_size
        participation = calculate_participation_percent
        sic_code = sponsor_contribution.sic_code
        enrolling_employees = employees_enrolling
        group_mapper = CensusEmployeeMemberGroupMapper.new(enrolling_employees, reference_product, coverage_start, sponsored_benefit)
        mapped_eligible_roster = group_mapper.lazy.map do |e_roster_entry|
          roster_eligibility_optimizer.calculate_optimal_group_for(contribution_model, e_roster_entry, sponsor_contribution)
        end
        p_determination_builder.create_pricing_determinations(sponsored_benefit, reference_product, pricing_model, mapped_eligible_roster, group_size, participation, sic_code)
      end

      def calculate_normal_costs(
        pricing_model,
        contribution_model,
        reference_product,
        sponsor_contribution,
        p_calculator,
        c_calculator,
        roster_eligibility_optimizer,
        sponsored_benefit
      )
        price_total = 0.00
        contribution_total = 0.00
        enrolling_employees = employees_enrolling
        group_mapper = CensusEmployeeMemberGroupMapper.new(enrolling_employees, reference_product, coverage_start, sponsored_benefit)
        group_mapper.each do |ce_roster|
          roster_group = roster_eligibility_optimizer.calculate_optimal_group_for(contribution_model, ce_roster, sponsor_contribution)
          price_group = p_calculator.calculate_price_for(pricing_model, roster_group, sponsor_contribution)
          contribution_group = c_calculator.calculate_contribution_for(contribution_model, price_group, sponsor_contribution)
          price_total = price_total + contribution_group.group_enrollment.product_cost_total
          contribution_total = contribution_total + contribution_group.group_enrollment.sponsor_contribution_total
        end
        [price_total, contribution_total]
      end

      def eligible_employee_criteria
        ::CensusEmployee.where(
          :benefit_sponsorship_id => benefit_sponsorship.id,
          :hired_on => {"$lte" => coverage_start},
          "$or" => [
            { "terminated_on" => nil },
            { "terminated_on" => { "$gt" => coverage_start } },
            { "terminated_on" => { "$lte" => coverage_start }, "aasm_state" => { "$in" => ["cobra_eligible", "cobra_linked", "cobra_termination_pending"] } }
          ]
        )
      end

      def eligible_employee_count
        @eligible_employee_count ||= eligible_employee_criteria.count
      end

      def employees_enrolling
        eligible_employee_criteria.where({expected_selection: "enroll"})
      end

      def employees_enrolling_and_waiving
        eligible_employee_criteria.where({expected_selection: {"$in" => ["enroll", "waive"]}})
      end

      def calculate_group_size
        employees_enrolling.count
      end

      def calculate_participation_percent
        enrolling_count = employees_enrolling_and_waiving.count
        return 0.0 if enrolling_count < 1
        (enrolling_count.to_f / eligible_employee_count) * 100.0
      end
    end
  end
end
