# frozen_string_literal: true

# Base class to generate EnrollApp EmployerProfile and child models from an existing PlanDesign Proposal
module SponsoredBenefits
  module BenefitApplications
    class EmployerProfileBuilder
      include Config::AcaHelper

      attr_reader :plan_design_organization,
                  :plan_design_proposal,
                  :benefit_application,
                  :employer_profile,
                  :organization

      def initialize(plan_design_proposal, organization = nil)
        @plan_design_proposal = plan_design_proposal
        @plan_design_organization = @plan_design_proposal.plan_design_organization

        @profile = @plan_design_proposal.profile
        @benefit_application = @profile.benefit_application

        # TODO: #FIXME We dont have owner_profile_id in plan design organization for new prospect employers
        # So we dont have a mapping from plan design organization to ::EmployerProfile.
        # If this is not correct, then we need to fix the below line.
        @organization = organization #|| ::EmployerProfile.find_or_create_by_plan_design_organization(@plan_design_organization)
        @organization_exists = @organization.persisted?
      end

      def quote_valid?
        return true if aca_state_abbreviation == "DC"
        validate_effective_date
      end

      def validate_effective_date
        if @organization.present? && aca_state_abbreviation == "MA"
          benefit_sponsorship = @organization.active_benefit_sponsorship
          if (benefit_sponsorship.present? && benefit_sponsorship.active_benefit_application.present?) || benefit_sponsorship.is_conversion?
            base_benefit_application = benefit_sponsorship.active_benefit_application || benefit_sponsorship.published_benefit_application

            raise "Quote effective date is invalid" if base_benefit_application.end_on.to_date.next_day != plan_design_proposal.effective_date
          end
        else
          if @organization.present? && @organization.active_plan_year.present? || @organization.is_converting?
            base_plan_year = @organization.active_plan_year || @organization.published_plan_year
            raise "Quote effective date is invalid" if base_plan_year.end_on.to_date.next_day != plan_design_proposal.effective_date
          end
        end

        true
      end

      def cancel_any_previous_benefit_applications(organization, new_benefit_application)
        benefit_sponsorship = organization.active_benefit_sponsorship
        benefit_sponsorship&.benefit_applications&.each do |benefit_application|
          next unless (new_benefit_application.id != benefit_application.id) && (benefit_application.start_on == new_benefit_application.start_on)
          benefit_application.cancel! if benefit_application.may_cancel?
        end
      end

      def add_employer_profile
        add_census_members unless @organization_exists
      end

      def add_benefit_sponsors_benefit_application
        # if aca_state_abbreviation == "DC"
        #   quote_benefit_application = @benefit_application.to_plan_year(@organization)
        #   if @organization.employer_profile.active_plan_year.present? || @organization.employer_profile.is_converting?
        #     quote_benefit_application.renew_plan_year if quote_benefit_application.may_renew_plan_year?
        #   end

        #   if quote_benefit_application.valid? && @organization.valid?
        #     @organization.employer_profile.plan_years.each do |plan_year|
        #       next unless plan_year.start_on == quote_benefit_application.start_on
        #       if plan_year.is_renewing?
        #         plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
        #       else
        #         plan_year.cancel! if plan_year.may_cancel?
        #       end
        #     end
        #   end
        #   @organization.employer_profile.plan_years << quote_benefit_application
        #   @organization.save!
        #   @organization.employer_profile.census_employees.each do |census_employee|
        #     census_employee.save
        #   end
        # else

        # Migrated to new model in DC
        quote_benefit_application = @benefit_application.to_benefit_sponsors_benefit_application(@organization)

        cancel_any_previous_benefit_applications(@organization, quote_benefit_application) if quote_benefit_application.valid? && quote_benefit_application.save!

        @organization.active_benefit_sponsorship.census_employees.each(&:save)
        # end
      end

      # Output the employer_profile
      def employer_profile
        validate_employer_profile

        [@employer_profile, census_employees]
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

      def validate_census_employees; end

      def validate_employer_profile
        raise "you must provide an employer Federal Tax ID number" if @plan_design_organization.fein.blank?
      end

      private

       # Build census members for new employer_profiles only
      def add_census_members
        add_benefit_group_assignment
      end

      def add_benefit_group_assignment; end




    end
  end
end
