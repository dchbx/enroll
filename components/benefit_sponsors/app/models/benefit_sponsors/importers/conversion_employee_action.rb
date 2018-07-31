module BenefitSponsors
  module Importers
    class ConversionEmployeeAction < Importers::ConversionEmployeeCommon
      validate :validate_fein
      validate :validate_relationships
      validates_length_of :fein, is: 9

      def initialize(opts = {})
        super(opts)
        @original_attributes = opts
      end

      def validate_fein
        return true if fein.blank?
        found_employer = find_employer
        if found_employer.nil?
          errors.add(:fein, "does not exist")
        end
      end

      def validate_relationships
        (1..8).to_a.each do |num|
          dep_ln = "dep_#{num}_name_last".to_sym
          dep_rel = "dep_#{num}_relationship".to_sym
          unless self.send(dep_ln).blank?
            if self.send(dep_rel).blank?
              errors.add("dep_#{num}_relationship", "invalid.  must be one of: #{RELATIONSHIP_MAP.keys.join(", ")}")
            end
          end
        end
      end

      def save
        return false unless valid?
        found_employee = find_employee
        employer = find_employer

        if employer.legal_name.match(/OLD DO NOT USE/i).present?
          puts "OLD DO NOT USE #{fein} #{employer_name}"
        end


        proxy = found_employee.nil? ? BenefitSponsors::Importers::ConversionEmployeeCreate.new(@original_attributes) : ::Importers::ConversionEmployeeUpdate.new(@original_attributes)
        result = proxy.save
        propagate_warnings(proxy)
        propagate_errors(proxy)
        result
      end

      def find_employer
        org = BenefitSponsors::Organizations::Organization.where(fein: fein).first
        return nil unless org
        org.employer_profile
      end

      def find_employee
        return @found_employee unless @found_employee.nil?
        return nil if subscriber_ssn.blank?
        found_employer = find_employer
        benefit_sponsorship = found_employer.active_benefit_sponsorship
        return nil if found_employer.nil?
        candidate_employees = CensusEmployee.where({
                                                       benefit_sponsors_employer_profile_id: found_employer.id,
                                                       benefit_sponsorship_id: benefit_sponsorship.id,
                                                       encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
                                                   })
        non_terminated_employees = candidate_employees.reject do |ce|
          (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
        end

        @found_employee = non_terminated_employees.sort_by(&:hired_on).last
      end

      def propagate_warnings(proxy)
        proxy.warnings.each do |attr, err|
          warnings.add(attr, err)
        end
      end

      def propagate_errors(proxy)
        proxy.errors.each do |attr, err|
          errors.add(attr, err)
        end
      end

    end
  end
end
