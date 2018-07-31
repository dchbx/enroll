# Base class to generate EnrollApp EmployerProfile and child models from an existing PlanDesign Proposal
module SponsoredBenefits
  module BenefitApplications
    class EmployerProfileBuilder

      attr_reader :plan_design_organization,
                  :plan_design_proposal,
                  :benefit_application,
                  :employer_profile

      def initialize(plan_design_proposal, employer_profile=nil)

        @plan_design_proposal = plan_design_proposal
        @plan_design_organization = @plan_design_proposal.plan_design_organization

        @profile = @plan_design_proposal.profile
        @benefit_application = @profile.benefit_application

        # TODO #FIXME We dont have owner_profile_id in plan design organization for new prospect employers
        # So we dont have a mapping from plan design organization to ::EmployerProfile.
        # If this is not correct, then we need to fix the below line.
        @employer_profile = employer_profile #|| ::EmployerProfile.find_or_create_by_plan_design_organization(@plan_design_organization)
        @employer_profile_exists = @employer_profile.persisted?
      end

      def quote_valid?
        validate_effective_date
      end

      def validate_effective_date
        if @employer_profile.present?
          if @employer_profile.active_plan_year.present? || @employer_profile.is_converting?
            base_plan_year = @employer_profile.active_plan_year || @employer_profile.published_plan_year

            if base_plan_year.start_on.next_year != plan_design_proposal.effective_date
              raise "Quote effective date is invalid"
            end
          end
        end

        return true
      end

      def add_employer_profile
        add_census_members unless @employer_profile_exists
      end

      def add_plan_year
        quote_plan_year = @benefit_application.to_plan_year

        if @employer_profile.active_plan_year.present? || @employer_profile.is_converting?
          quote_plan_year.renew_plan_year if quote_plan_year.may_renew_plan_year?
        end

        if quote_plan_year.valid? && @employer_profile.valid?
          @employer_profile.plan_years.each do |plan_year|
            next unless plan_year.start_on == quote_plan_year.start_on
            if plan_year.is_renewing?
              plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
            else
              plan_year.cancel! if plan_year.may_cancel?
            end
          end
        end

        @employer_profile.plan_years << quote_plan_year
        @employer_profile.save!

        @employer_profile.census_employees.each do |census_employee|
          census_employee.save
        end
      end


      # Output the employer_profile
      def employer_profile
        validate_employer_profile

        return @employer_profile, census_employees
      end

      def census_employees

        @census_employees = []

        @census_employees = benefit_sponsor_enrollment_group

          # benefit_sponsorship_id
          # size
          # waived_count
          # classifications (family, employee_only...)
          # has_many or embeds_many?

      end

      def validate_census_employees
      end


      def validate_employer_profile
        raise "you must provide an employer Federal Tax ID number" if @plan_design_organization.fein.blank?

      end

      private

       # Build census members for new employer_profiles only
      def add_census_members
        add_benefit_group_assignment
      end


      def add_benefit_group_assignment
      end




    end
  end
end
