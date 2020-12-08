module BenefitSponsors
  module Importers
    class ConversionEmployeePolicy < ::Importers::ConversionEmployeePolicy

      def find_benefit_group_assignment
        return @found_benefit_group_assignment unless @found_benefit_group_assignment.nil?
        census_employee = find_employee
        return nil unless census_employee

        benefit_application = fetch_application_based_sponsored_kind
        found_employer = find_employer

        if benefit_application
          candidate_bgas = census_employee.benefit_group_assignments.where(:"benefit_package_id".in  => benefit_application.benefit_packages.map(&:id))
          @found_benefit_group_assignment = candidate_bgas.sort_by(&:start_on).last
        end
      end

      def current_benefit_application(employer)
        if (employer.organization.active_benefit_sponsorship.source_kind.to_s == "conversion")
          employer.benefit_applications.where(:aasm_state => :imported).first
        else
          employer.benefit_applications.where(:aasm_state => :active).first
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
        # Date.today converted to TimeKeeper.date_of_record
        non_terminated_employees = candidate_employees.reject do |ce|
          !ce.employment_terminated_on.blank? && ce.employment_terminated_on <= TimeKeeper.date_of_record
        end

        @found_employee = non_terminated_employees.sort_by(&:hired_on).last
      end

      def find_plan
        return @plan unless @plan.nil?
        return nil if hios_id.blank?
        clean_hios = hios_id.strip

        if sponsored_benefit_kind == :dental
          corrected_hios_id = clean_hios.split("-")[0]
        else
          corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
        end

        sponsor_benefit = find_sponsor_benefit

        if sponsor_benefit.source_kind == :conversion
          actual_start_on = (sponsor_benefit.benefit_package.end_on + 1.day).prev_year
          # hios = (sponsored_benefit_kind == :dental ? hios_id : corrected_hios_id)
          ::BenefitMarkets::Products::Product.where(hios_id: corrected_hios_id).detect do |product|
            product.application_period.cover?(actual_start_on)
          end
        else
          sponsor_benefit.product_package.products.where(hios_id: corrected_hios_id).first
        end
      end

      def find_sponsor_benefit
        benefit_application = fetch_application_based_sponsored_kind
        benefit_package = benefit_application.benefit_packages.first
        benefit_package.sponsored_benefits.unscoped.detect{|sponsored_benefit|
          sponsored_benefit.product_kind == sponsored_benefit_kind
        }
      end

      # for normal :conversion, :mid_plan_year_conversion we use :imported plan year
      # but while creating :dental sponsored_benefit we will add it on :active benefit_application
      def fetch_application_based_sponsored_kind
        employer = find_employer
        benefit_application = sponsored_benefit_kind == :dental ? employer.active_benefit_application : current_benefit_application(employer)
        benefit_application
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
