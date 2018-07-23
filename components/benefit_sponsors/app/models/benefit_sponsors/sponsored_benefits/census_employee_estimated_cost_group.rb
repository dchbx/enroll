module BenefitSponsors
    module SponsoredBenefits
      class CensusEmployeeEstimatedCostGroup
        EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled, :census_member) do
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
              false,
              census_employee
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
                  map_ce_disabled(cm.employee_relationship),
                  cm
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
              {group_enrollment: group_enrollment, group_id: census_employee.id}
            )
          end
        end

        attr_reader :benefit_sponsorship, :coverage_start

        def initialize(b_sponsorship, c_start)
          @benefit_sponsorship = b_sponsorship
          @coverage_start = c_start
        end

        def calculate(sponsored_benefit, product, p_package)
          pricing_model = p_package.pricing_model
          contribution_model = p_package.contribution_model
          p_calculator = pricing_model.pricing_calculator
          c_calculator = contribution_model.contribution_calculator
          sponsor_contribution = sponsored_benefit.sponsor_contribution
          roster_eligibility_optimizer = RosterEligibilityOptimizer.new(contribution_model)
          calculate_employee_groups(
            pricing_model,
            contribution_model,
            product,
            sponsor_contribution,
            p_calculator,
            c_calculator,
            roster_eligibility_optimizer,
            sponsored_benefit
          )
        end

        protected

        def calculate_employee_groups(
          pricing_model,
          contribution_model,
          product,
          sponsor_contribution,
          p_calculator,
          c_calculator,
          roster_eligibility_optimizer,
          sponsored_benefit
        )
          group_mapper = CensusEmployeeMemberGroupMapper.new(eligible_employee_criteria, product, coverage_start, sponsored_benefit)
          group_mapper.map do |ce_roster|
            roster_group = roster_eligibility_optimizer.calculate_optimal_group_for(contribution_model, ce_roster, sponsor_contribution)
            price_group = p_calculator.calculate_price_for(pricing_model, roster_group, sponsor_contribution)
            c_calculator.calculate_contribution_for(contribution_model, price_group, sponsor_contribution)
          end
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
      end
    end
  end

