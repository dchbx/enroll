module BenefitSponsors
  module Importers
    class ConversionEmployeePolicy < ::Importers::ConversionEmployeePolicy

      def find_benefit_group_assignment
        return @found_benefit_group_assignment unless @found_benefit_group_assignment.nil?
        census_employee = find_employee
        return nil unless census_employee

        found_employer = find_employer
        benefit_application = find_employer.active_benefit_application

        if benefit_application
          candidate_bgas = census_employee.benefit_group_assignments.where(:"benefit_package_id".in  => benefit_application.benefit_packages.map(&:id))
          @found_benefit_group_assignment = candidate_bgas.sort_by(&:start_on).last
        end
      end

      def find_employee
        return @found_employee unless @found_employee.nil?
        return nil if subscriber_ssn.blank?
        found_employer = find_employer
        return nil if found_employer.nil?
        benefit_sponsorship = found_employer.active_benefit_sponsorship
        candidate_employees = CensusEmployee.where({
                                                       benefit_sponsors_employer_profile_id: found_employer.id,
                                                       benefit_sponsorship_id: benefit_sponsorship.id,
                                                       # hired_on: {"$lte" => start_date},
                                                       encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
                                                   })
        non_terminated_employees = candidate_employees.reject do |ce|
          (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
        end

        @found_employee = non_terminated_employees.sort_by(&:hired_on).last
      end

      def find_plan
        return @plan unless @plan.nil?
        return nil if hios_id.blank?
        clean_hios = hios_id.strip
        corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
        sponsor_benefit = find_sponsor_benefit
        sponsor_benefit.product_package.products.where(hios_id: corrected_hios_id ).first
      end

      def find_sponsor_benefit
        employer = find_employer
        benefit_application = employer.active_benefit_application
        benefit_package = benefit_application.benefit_packages.first
        sponsor_benefit = benefit_package.sponsored_benefits.first
      end

      def find_employer
        return @found_employer unless @found_employer.nil?
        org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        return nil unless org
        @found_employer = org.employer_profile
      end

    end
  end
end
