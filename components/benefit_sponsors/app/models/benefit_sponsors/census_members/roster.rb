module BenefitSponsors
  module CensusMembers
    class Roster
      include Enumerable

      attr_reader :roster_kind

      ROSTER_KINDS = [:plan_design, :employer_profile]

      def initialize(*members)
        @roster_kind  = :employer_profile
        @members      = members

        member_class_for(@members.first) if @members.size > 0
      end

      def each(&block)
        @members.each { |member| block.call(member) }
      end

      def member_class_for(member_instance)
        case member_instance.class_name
        when "BenefitSponsors::CensusMembers::PlanDesignCensusEmployee", "BenefitSponsors::CensusMembers::PlanDesignCensusDependent"
          @roster_kind  = :plan_design
          @member_klass = BenefitSponsors::CensusMembers::PlanDesignCensusEmployee
        when "PlanDesignCensusEmployee", "PlanDesignCensusDependent"
          @roster_kind  = :employer_profile
          @member_klass = ::CensusEmployee
        end
      end

      def add_members_by_benefit_sponsor(benefit_sponsor)
        @members = benefit_sponsor.census_employees.collect { |member| add_member(member) }
      end


      def benefit_rating_category_for(census_employee)
      end


      def add_member(new_member)
        
        census_employee = BenefitSponsors::CensusMembers::PlanDesignCensusEmployee.new(serialize_attributes(new_member.attributes))
        census_employee.benefit_sponsorship_id = benefit_sponsorship.id
        census_employee.ssn = census_employee.ssn if census_employee.ssn.present?

        census_employee.census_dependents.each do |dependent|
          census_employee.census_dependents << add_member_dependent(dependent)
        end
        census_employee
      end

      def add_member_dependent(new_census_dependent)
        census_dependent = BenefitSponsors::CensusMembers::CensusDependent.new(dependent_attributes(new_census_dependent.attributes))
        census_dependent.ssn= census_dependent.ssn if census_dependent.ssn.present?
        census_dependent
      end


      def census_employees
        @census_employees
      end

      private

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


      # :spouse :domestic_partner :child_under_26  :child_26_and_over :disabled_child_26_and_over

      maps = [ 
        composite_rating: { 
          employee_only: {
            title: "Employee Only", 
            visible: true,
            ordinal_position: 1,

            eligibility_criteria: {
              member_count: 1..1,
              relationships_excluded: [:child_under_26, :child_26_and_over, :disabled_child_26_and_over],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                  ]
              }, # composition
            }, # eligibility_criteria
          }, # employee_only

          employee_and_spouse: {
            title: "Employee and Spouse", 
            visible: true,
            ordinal_position: 2,
            eligibility_criteria: {
              member_count: 2..2,
              relationships_excluded: [:child_under_26, :child_26_and_over, :disabled_child_26_and_over],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                    {
                      relationships_included: [:spouse, :domestic_partner],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },       
                  ]
              }, # composition
            }, # eligibility criteria
          }, #employee and spouse

          employee_and_one_or_more_dependents: {
            title: "Employee and One or More Dependents", 
            visible: true,
            ordinal_position: 3,
            eligibility_criteria: {
              member_count: 2..20,
              relationships_excluded: [:spouse, :domestic_partner],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                    {
                      relationships_included: [:spouse],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                  ]
              }, # composition
            }, # eligibility criteria
          }, # employee_and_one_or_more_dependents


          family: {
            title: "Family", 
            visible: true,
            ordinal_position: 4,
            eligibility_criteria: {
              member_count: 3..20,
              relationships_excluded: [],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                    {
                      relationships_included: [:spouse, :domestic_partner],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },    
                    {
                      relationships_included: [:child_under_26, :child_26_and_over, :disabled_child_26_and_over],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },    
                  ]
              }, # composition
            }, # eligibility criteria
          }, # family

        }, # composite rating


        choice_rating: { 

        }, # choice rating

      ]
    end
  end
end
