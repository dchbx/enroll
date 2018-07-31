module SponsoredBenefits
  module Forms
    class PlanDesignCensusEmployee < CensusMember

      attr_accessor :hired_on, :is_business_owner

      def initialize(attrs = {})
        super
      end
   
      def census_dependents=(attrs)
      end

      def save
        census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployeeBuilder.build do |builder|
          builder.add_first_name(first_name)
          builder.add_last_name(last_name)
          builder.add_ssn(ssn)
          builder.add_dob(dob)
          builder.add_dependent(dependent)
        end

        census_employee.save
      end
    end
  end
end
