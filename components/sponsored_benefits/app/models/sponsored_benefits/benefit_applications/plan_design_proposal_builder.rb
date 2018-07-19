module SponsoredBenefits
  module BenefitApplications
    class PlanDesignProposalBuilder

      attr_reader :plan_design_organization, :census_employees

      def initialize(plan_design_organization, effective_date)
        @employer_profile = plan_design_organization.employer_profile
        @plan_design_organization = plan_design_organization
        @effective_date = effective_date
        @plan_design_proposal = plan_design_organization.plan_design_proposals.build(title: "Plan Design #{@effective_date.year}")
      end

      def add_plan_design_profile
        profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({
          sic_code: @employer_profile.sic_code
          })

        profile.benefit_sponsorships[0].assign_attributes({
          initial_enrollment_period: enrollment_dates[:effective_period], 
          annual_enrollment_period_begin_month: @effective_date.month
          })

        @plan_design_proposal.profile = profile
      end

      def add_benefit_application
        if benefit_sponsorship.present?
          benefit_application = benefit_sponsorship.benefit_applications.build
          benefit_application.effective_period= enrollment_dates[:effective_period]
          benefit_application.open_enrollment_period= enrollment_dates[:open_enrollment_period]
          benefit_application
        end
      end

      def add_plan_design_employees
        @census_employees = @employer_profile.census_employees.non_terminated.collect do |census_employee|
          add_plan_design_employee(census_employee)
        end
      end

      def add_plan_design_employee(census_employee)
        plan_design_census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new(serialize_attributes(census_employee.attributes))
        plan_design_census_employee.benefit_sponsorship_id = benefit_sponsorship.id
        plan_design_census_employee.ssn= census_employee.ssn if census_employee.ssn.present?
        census_employee.census_dependents.each do |dependent|
          plan_design_census_employee.census_dependents << build_census_dependent(dependent)
        end
        plan_design_census_employee
      end

      def add_proposal_state(aasm_state)
        @plan_design_proposal.aasm_state = aasm_state
      end

      def build_census_dependent(dependent)
        plan_design_dependent = SponsoredBenefits::CensusMembers::CensusDependent.new(dependent_attributes(dependent.attributes))
        plan_design_dependent.ssn= dependent.ssn if dependent.ssn.present?
        plan_design_dependent
      end
    
      def plan_design_proposal
        # Perform Validations
        if has_access?          
          @plan_design_proposal
        end
      end

      private

      # PlanDesigner access level to EmployerProfile:
      #   Full Broker Hired Access
      #   One-time Quote Access
      #   No Access
      def has_access?
        broker_agency_accounts =  @employer_profile.broker_agency_accounts.where(broker_agency_profile_id: plan_design_organization.broker_agency_profile.id) # Deprecate this
        broker_agency_accounts =  @employer_profile.broker_agency_accounts.where(benefit_sponsors_broker_agency_profile_id: plan_design_organization.broker_agency_profile.id) if broker_agency_accounts.blank?
        
        if broker_agency_accounts.present? && broker_agency_accounts.any?{|acc| acc.is_active?}
          return true
        end

        if broker_agency_accounts.present?
          raise "You no longer have permission to import employer information."
        end
      
        raise "You don't have permission to import employer information. Request One-time access."
      end

      def benefit_sponsorship
        @plan_design_proposal.profile.benefit_sponsorships[0]
      end

      def enrollment_dates
        BenefitApplications::BenefitApplication.enrollment_timetable_by_effective_date(@effective_date)
      end

      def serialize_attributes(attributes)
        params = ActionController::Parameters.new(attributes)
        params.permit(
          :first_name,
          :middle_name,
          :last_name,
          :name_sfx,
          :dob,
          :gender,
          :hired_on,
          :is_business_owner,
          :aasm_state,
          address: [
            :kind, :address_1, :address_2, :city, :state, :zip
          ],
          email: [
            :kind, :address
          ])
      end

      def dependent_attributes(attributes)
        params = ActionController::Parameters.new(attributes)
        params.permit(
          :first_name,
          :middle_name,
          :last_name,
          :dob,
          :employee_relationship,
          :gender
          )
      end
    end
  end
end
