module BenefitSponsors
  module Importers
    class ConversionEmployeeCommon < ::Importers::ConversionEmployeeCommon

      def find_employer
        org = BenefitSponsors::Organizations::Organization.where(fein: fein).first
        return nil unless org
        org.employer_profile
      end

      def find_employee
        return @found_employee unless @found_employee.nil?
        return nil if subscriber_ssn.blank?
        found_employer = find_employer
        return nil if found_employer.nil?
        candidate_employees = CensusEmployee.where({
                                                       employer_profile_id: found_employer.id,
                                                       benefit_sponsorship_id: benefit_sponsorship.id,
                                                       # hired_on: {"$lte" => start_date},
                                                       # encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
                                                   })
        non_terminated_employees = candidate_employees.reject do |ce|
          (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
        end

        @found_employee = non_terminated_employees.sort_by(&:hired_on).last
      end

    end
  end
end
